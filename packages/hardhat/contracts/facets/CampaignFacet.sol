// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibCampaignStorage.sol";
import "../libraries/LibAffiliateStorage.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "./Campaign.sol";
import "../interfaces/IERC173.sol";
import "../interfaces/ICampaignFacet.sol";
import "../libraries/Utilities.sol";

// TODO 
// all campaigns list

// * allows new affiliate sign up
/// @title CampaignFacet 
/// @author Danny Thomx
/// @notice Purpose: Create and Manage referral Campaigns for locks

contract CampaignFacet is ICampaignFacet, ReentrancyGuard {
  address public UNADUS;

  // mapping of lock address to campaign Ids
  mapping(address => address) public lockToCampaignId;
  mapping(address => bool) isCampaign;

  event NewCampaign(address campaignId, address owner, address nftAddress, uint256[] commissionRate);
  event NewReferee(address indexed campaignId, address indexed _buyer, address referrer, uint256 tokenId);

  modifier onlyOwner(address _contractAddress) {
    require(IERC173(_contractAddress).owner() == msg.sender, "Not Owner");
    _;
  }

  modifier onlyCampaignOwner(address _campaignId) {
    CampaignInfo memory _campaign = getCampaignData(_campaignId);
    require(_campaign.owner == msg.sender, "Not Campaign owner");
    _;
  }

  modifier onlyIfSufficientBalance(uint256 _amount) {
    require(address(UNADUS).balance >= _amount, "Insufficient Contract balance");
    _;
  }

  modifier onlyCampaign () {
    require(isCampaign[msg.sender], "Only Campaign Hook Allowed");
    _;
  }

  function isMember(address _user)public view returns(bool _isMember){
    address membershipLock = _getMembershipLock();
    if(membershipLock == address(0)) return false;
    _isMember = IPublicLockV12(membershipLock).getHasValidKey(_user);
  }

  function getPercentageWithdrawalFee()public view returns(uint256 fee){
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    return fee = appStorage.withdrawalFee;
  }

  function getMembershipLock()public view returns(address membershipLock){
    membershipLock = _getMembershipLock();
  }

  function setMembershipLock(address _membershipLock) public onlyOwner(UNADUS){
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.membershipLock = _membershipLock;
  }

  function setPercentageWithdrawalFee(uint256 _feePercentage) public onlyOwner(UNADUS){
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    appStorage.withdrawalFee = _feePercentage;
  }

  function withdrawFees()public nonReentrant onlyOwner(UNADUS) {
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    uint256 amount = appStorage.feesBalance;
    require(amount > 0, "Zero Fees balance");
    require(address(this).balance >= amount, "Insufficient Contract balance");
    // Send amount to owner address
    (bool sent,) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send Ether");
    // Deduct amount from fees balance
    _updateWithdrawalFeeBalance(amount, false);
  }

  function affiliateWithdraw(uint256 _amount, address _campaignId) public 
    nonReentrant 
    onlyIfSufficientBalance(_amount) 
  {
    AffiliateInfo storage affiliate = Utilities._getAffiliateData(_campaignId, msg.sender);
    // check affiliate exists
    require(affiliate.affiliateId != address(0), "Affiliate not found for Campaign Id");
    // Ensure affiliate has enough balance
    require(affiliate.balance >= _amount, "Insufficient balance: Affiliate total balance less than amount");
    // Calculate withdrawable balance and check if it's sufficient
    (uint256 withdrawableBalance, uint256[] memory directSalesTokenIds, uint256[] memory refereesSalesTokenIds) = Utilities._calculateAffiliateWithdrawableBalance(msg.sender, _campaignId);
    require(_amount <= withdrawableBalance, "Insufficient balance: Withdrawable balance less than amount");
    // Check for membership and transfer funds if applicable
    if (isMember(msg.sender)) {
      // Transfer funds to affiliate
      (bool success,) = msg.sender.call{value: withdrawableBalance}("");
      require(success, "Failed to send Ether");
      // Deduct withdrawable balance from affiliate balance
      _deductBalance(_campaignId, withdrawableBalance, true);
      // Mark tokens as cashed out
      _markAsCashedOutTokens(_campaignId, directSalesTokenIds, refereesSalesTokenIds);
      // Exit after function execution
      return;
    }
    // Calculate withdrawal fee
    uint256 withdrawalFee = _calculateWithdrawalFee(withdrawableBalance);
    // Deduct fee from withdrawable balance
    uint256 amountAfterFees = withdrawableBalance - withdrawalFee;
    // Send amountAfterFees to affiliate address
    (bool sent,) = msg.sender.call{value: amountAfterFees}("");
    require(sent, "Failed to send Ether");
    // Update withdrawal fee balance
    _updateWithdrawalFeeBalance(withdrawalFee, true);
    // Deduct withdrawable balance from affiliate balance
    _deductBalance(_campaignId, withdrawableBalance, true);
    // Mark directSales and refereesSales tokenIds as cashed out
    _markAsCashedOutTokens(_campaignId, directSalesTokenIds, refereesSalesTokenIds);
  }

  function creatorWithdraw(uint256 _amount, address _campaignId) public 
    nonReentrant 
    onlyIfSufficientBalance(_amount) 
    onlyCampaignOwner(_campaignId)
  {
    // Fetch available balance and check if it's sufficient
    uint256 availableBalance = Utilities._fetchCreatorBalance( _campaignId);
    require(_amount <= availableBalance, "Insufficient balance: Withdrawable balance less than amount");
    // Check for membership and transfer funds
    if (isMember(msg.sender)) {
      // Transfer funds to creator
      (bool success,) = msg.sender.call{value: availableBalance}("");
      require(success, "Failed to send Ether");
      // Deduct availableBalance from creator balance
      _deductBalance(_campaignId, availableBalance, false);
      // Exit function execution
      return;
    }
    // Calculate withdrawal fee
    uint256 withdrawalFee = _calculateWithdrawalFee(availableBalance);
    require(availableBalance >= withdrawalFee, "Balance less than withdrawal fees");
    // Deduct fee from withdrawable balance
    uint256 amountAfterFees = availableBalance - withdrawalFee;
    // Send amountAfterFees to creator address
    (bool sent,) = msg.sender.call{value: amountAfterFees}("");
    require(sent, "Failed to send Ether");
    // Deduct availableBalance from creator balance
    _deductBalance(_campaignId, availableBalance, false);
    // Update withdrawal fee balance
    _updateWithdrawalFeeBalance(withdrawalFee, true);
  }

  function getCampaignForLock( address _lockAddress) external view returns (CampaignInfo memory) {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    require(lockToCampaignId[_lockAddress] != address(0), "No campaign exist for this lock");
    address campaignId = lockToCampaignId[_lockAddress];
    return cs.campaignsById[campaignId];
  }

  function getCampaignData(address _campaignId) public view returns (CampaignInfo memory){
    return Utilities._getCampaignData(_campaignId);
  }
  
  function getMaxTiers() external pure returns(uint){
    return AppConstants.MAX_TIERS;
  }

  function initUNADUS(address _UNADUSAddress) external onlyOwner(_UNADUSAddress) {
    require(_UNADUSAddress != address(0), "Invalid Address: Zero address");
    UNADUS = _UNADUSAddress;
  }

  function createCampaign(string memory _name, address _lockAddress, uint256 _level1Commission, uint256 _level2Commission, uint256 _level3Commission, uint256 _delay) external {
    require(UNADUS != address(0),
        "UNADUS Uninitialized"
    );
    require(
        lockToCampaignId[_lockAddress] == address(0),
        "Campaign exist for this lock"
    );
    require(_isLockManager(_lockAddress), "Not Lock Manager");
    CampaignInfo memory _newCampaign;
    uint256[] memory tiersCommission = new uint256[](3);
    tiersCommission[0] = _level1Commission;
    tiersCommission[1] = _level2Commission;
    tiersCommission[2] = _level3Commission;
    // deploy campaign (onKeyPurchase) hook to track purchases for campaign 
    CampaignHook newCampaignId = new CampaignHook(UNADUS, _lockAddress);
    // create new campaign
    _newCampaign.name = _name;
    _newCampaign.campaignId = address(newCampaignId);
    _newCampaign.tiersCommission = tiersCommission;
    _newCampaign.owner = msg.sender;
    _newCampaign.lockAddress = _lockAddress;
    _newCampaign.delay = _delay;
    // update lockToCampaignId mapping for this lock
    lockToCampaignId[_lockAddress] = address(newCampaignId);
    // update isCampaignHook mapping for new campaign
    isCampaign[address(newCampaignId)] = true;
    // update campaign storage
    Utilities._updateCampaignStorage(_newCampaign);
    // set lock referral commission for this campaign
    uint256 totalCommission =Utilities._getTotalTiersCommission(_newCampaign);
    IPublicLockV12(_lockAddress).setReferrerFee(UNADUS, totalCommission);
    // set campaignId as onKeyPurchaseHook for the lock
    IPublicLockV12(_lockAddress).setEventHooks(address(newCampaignId), address(0),address(0),address(0),address(0),address(0),address(0));
    // add CampaignHook as lock manager
    IPublicLockV12(_lockAddress).addLockManager(address(newCampaignId));
    // emit NewCampaign event
    emit NewCampaign(address(newCampaignId), msg.sender, _lockAddress, tiersCommission);
  }

  function setName(string memory _newName, address _campaignId) external onlyCampaignOwner(_campaignId){
    CampaignInfo memory _campaign = getCampaignData(_campaignId);
    require(_campaign.owner == msg.sender, "Not Campaign owner");
    _campaign.name = _newName;
    Utilities._updateCampaignStorage(_campaign);
  }

  // commission is expressed in basis points (ie 100% is 10000, 10% is 1000, 1% is 100)
  function setTiersCommission(address _campaignId, uint256 _level1Commission, uint256 _level2Commission, uint256 _level3Commission) external onlyCampaignOwner(_campaignId){
    CampaignInfo memory _campaign = getCampaignData(_campaignId);
    require(_campaign.campaignId != address(0), "Invalid CampaignId");
    require(_campaign.owner == msg.sender, "Not Campaign owner");
    uint256[] memory tiersCommission = new uint256[](3);
    tiersCommission[0] = _level1Commission;
    tiersCommission[1] = _level2Commission;
    tiersCommission[2] = _level3Commission;
    _campaign.tiersCommission = tiersCommission;
    Utilities._updateCampaignStorage(_campaign);
  }

  function onReferredPurchase(
      address _campaignId,
      uint256 _tokenId,
      address _recipient,
      address _affiliateAddress,
      uint256 _commission
  ) external onlyCampaign returns (bool){
    // emit new referee event
    emit NewReferee(_campaignId, _recipient, _affiliateAddress, _tokenId);
    // create new referee data
    RefereeInfo memory _newReferee;
    _newReferee.campaignId = _campaignId;
    _newReferee.id = _recipient;
    _newReferee.referrer = _affiliateAddress;
    _newReferee.keyPurchased = _tokenId;
    // update referee storage
    _updateRefereeStorage(_newReferee, _affiliateAddress);
    Utilities._addAffiliateReferee(_affiliateAddress, _campaignId, _recipient);

    // update affiliates' commission balance
    (address levelTwoReferrerAddress, address levelThreeReferrerAddress) = Utilities._getMultiLevelReferrers(_affiliateAddress, _campaignId);
    (uint256 levelOneShare, uint256 levelTwoShare, uint256 levelThreeShare) = Utilities._calculateAffiliatesPayout(_commission, _campaignId);
    AffiliateUplineData memory affiliateData = AffiliateUplineData({
      campaignId: _campaignId,
      affiliateId: _affiliateAddress,
      levelTwoReferrer: levelTwoReferrerAddress,
      levelThreeReferrer: levelThreeReferrerAddress
    });
    Utilities._updateAffiliateStorage( _tokenId, levelOneShare, _affiliateAddress, affiliateData);
    if(levelTwoReferrerAddress != address(0)) Utilities._updateAffiliateStorage(_tokenId, levelTwoShare,levelTwoReferrerAddress, affiliateData);
    if(levelThreeReferrerAddress != address(0)) Utilities._updateAffiliateStorage(_tokenId, levelThreeShare, levelThreeReferrerAddress, affiliateData);
    Utilities._updateCampaignPayoutData(levelOneShare, levelTwoShare, levelThreeShare, affiliateData);
    return true;
  }

  function onNonReferredPurchase(address _campaignId, uint256 _commission) external onlyCampaign returns (bool){
    CampaignInfo memory _campaign = getCampaignData(_campaignId);
    //update campaign's non-commission balance
    _campaign.nonCommissionBalance += _commission;
    // update _campaign in storage
    Utilities._updateCampaignStorage(_campaign);
    return true;
  }

  function _markAsCashedOutTokens(address _campaignId, uint[] memory _directSalesTokenIds, uint[] memory _refereesSalesTokenIds) private {
    CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();

    for (uint i=0; i<_directSalesTokenIds.length; i++) {
      campaignStorage.isCashedOutToken[_campaignId][_directSalesTokenIds[i]] = true;
    }

    for (uint j=0; j< _refereesSalesTokenIds.length; j++) {
      campaignStorage.isCashedOutToken[_campaignId][_refereesSalesTokenIds[j]] = true;
    }
  }

  function _calculateWithdrawalFee(uint256 _amount) internal view returns (uint256 withdrawalFee) {
    uint256 FEE_PERCENTAGE = getPercentageWithdrawalFee();
    withdrawalFee = (_amount * FEE_PERCENTAGE) / 100;
  }

  function _getMembershipLock()internal view returns(address){
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.membershipLock;
  }

  function _isLockManager(address _lockAddress)
    internal
    view
    returns (bool isManager)
  {
    isManager = IPublicLockV12(_lockAddress).isLockManager(msg.sender);
  }

  function _updateWithdrawalFeeBalance(uint256 _amount, bool isDeposit)private {
    AppStorage storage _appStorage = LibAppStorage.diamondStorage();
    isDeposit ? _appStorage.feesBalance += _amount : _appStorage.feesBalance -= _amount;
  }

  function _deductBalance(address _campaignId, uint256 _withdrawalAmount, bool _isAffiliate)private {
    AffiliateInfo storage affiliate = Utilities._getAffiliateData(_campaignId, msg.sender);
    CampaignInfo memory campaign = Utilities._getCampaignData(_campaignId);
    // check if creator/ Affiliate
    if(!_isAffiliate){
      // If user is a creator (i.e not an affiliate) deduct withdrawal amount from nonCommissionBalance for the campaign
      campaign.nonCommissionBalance -= _withdrawalAmount;
      // update campaign storage
      Utilities._updateCampaignStorage(campaign);

      return;
    }
    // deduct withdrawal amount from affiliateBalance
    affiliate.balance -= _withdrawalAmount;
    // deduct withdrawal amount from commissionBalance for campaign
    campaign.commissionBalance -= _withdrawalAmount;
    // update campaign storage
    Utilities._updateCampaignStorage(campaign);
  }

  function _updateRefereeStorage(RefereeInfo memory _referee, address _referrer) private {
    RefereeStorage storage _refereeStorage = LibRefereeStorage.diamondStorage();
    // add new referee to referee data mapping
    _refereeStorage.refereeData[_referee.id][_referee.campaignId] = _referee;
    // if referrer not zero address add as the referrer 
    if(_referrer != address(0)) _refereeStorage.referrerOf[_referee.id][_referee.campaignId] = _referrer;
    // update allReferees list
    AppStorage storage _appStorage = LibAppStorage.diamondStorage();
    bool _isReferee = _appStorage.isReferee[_referee.id];
    if(!_isReferee){
        _refereeStorage.allReferees.push(_referee.id);
        _appStorage.isReferee[_referee.id] = true;
    }
  }
}