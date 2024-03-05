// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibCampaignStorage.sol";
import "../libraries/LibAffiliateStorage.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "./Campaign.sol";
import "../interfaces/IERC173.sol";
import "../interfaces/ICampaignFacet.sol";
import "../libraries/Utilities.sol";

// * allows new affiliate sign up
/// @title CampaignFacet 
/// @author Danny Thomx
/// @notice Purpose: Create and Manage referral Campaigns for locks

contract CampaignFacet is ICampaignFacet {
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

  modifier onlyCampaign () {
    require(isCampaign[msg.sender], "Only Campaign Hook Allowed");
    _;
  }
 
  function _isLockManager(address _lockAddress)
    internal
    view
    returns (bool isManager)
  {
    isManager = IPublicLockV12(_lockAddress).isLockManager(msg.sender);
  }

  function getCampaignForLock( address _lockAddress) external view returns (CampaignInfo memory) {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    require(lockToCampaignId[_lockAddress] != address(0), "No campaign exist for this lock");
    address campaignId = lockToCampaignId[_lockAddress];
    return cs.campaignsById[campaignId];
  }

  function getCampaignData(address _campaignId) public view returns (CampaignInfo memory){
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    return cs.campaignsById[_campaignId];
  }
  
  function getMaxTiers() external pure returns(uint){
    return AppConstants.MAX_TIERS;
  }

  function initUNADUS(address _UNADUSAddress) external onlyOwner(_UNADUSAddress) {
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
    // CampaignInfo memory _campaign = getCampaignData(_campaignId);
    // create new referee data
    RefereeInfo memory _newReferee;
    _newReferee.campaignId = _campaignId;
    _newReferee.id = _recipient;
    _newReferee.referrer = _affiliateAddress;
    _newReferee.keyPurchased = _tokenId;
    // update referee storage
    _updateRefereeStorage(_newReferee, _affiliateAddress);
    Utilities._addAffiliateReferee(_affiliateAddress, _campaignId, _recipient);
    // update campaign's commission balance
    // _campaign.commissionBalance += _commission;
    // update _campaign in storage
    // Utilities._updateCampaignStorage(_campaign);
    // update affiliates' commission balance
    (address levelTwoReferrerAddress, address levelThreeReferrerAddress) = Utilities._getMultiLevelReferrers(_affiliateAddress, _campaignId);
    (uint256 levelOneShare, uint256 levelTwoShare, uint256 levelThreeShare) = Utilities._calculateAffiliatePayout(_commission, _affiliateAddress, _campaignId);
    AffiliateUplineData memory affiliateData = AffiliateUplineData({
      campaignId: _campaignId,
      affiliateId: _affiliateAddress,
      levelTwoReferrer: levelTwoReferrerAddress,
      levelThreeReferrer: levelThreeReferrerAddress
    });
    Utilities._updateAffiliateStorage( _tokenId, levelOneShare, _affiliateAddress, affiliateData);
    if(levelTwoReferrerAddress != address(0)) Utilities._updateAffiliateStorage(_tokenId, levelTwoShare,levelTwoReferrerAddress, affiliateData);
    if(levelThreeReferrerAddress != address(0)) Utilities._updateAffiliateStorage(_tokenId, levelThreeShare, levelThreeReferrerAddress, affiliateData);
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