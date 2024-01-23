// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "../libraries/LibCampaignStorage.sol";
import "../libraries/LibAffiliateStorage.sol";
import "../libraries/LibRefereeStorage.sol";
import "./RefereeFacet.sol";
// Structs imported from AppStorage
error TOO_BIG();
error NOT_AUTHORIZED();

contract CampaignHook {
    address campaignId = address(this);
    mapping(address => bool) public isAffiliate;
    
    event NewReferee(address indexed campaignId, address indexed _buyer, address referrer, uint256 tokenId);
    event NewAffiliate(address indexed affiliate, address campaignId);

    // purpose
    // create onPurchase hook to track referrals for a lock
    // allows new affiliate sign up
    // manage campaign

    CampaignStorage internal s;

    constructor() { }

    function getReferrerFee(address _referrer)view public returns (uint256 referrerFees){
        address _lockAddress = _getCampaignLockAddress();
        return referrerFees = IPublicLockV12(_lockAddress).referrerFees(_referrer);
    }

    function getCampaignId() external view returns (address) {
        return campaignId;
    }

    function getCampaignData() external view returns (CampaignInfo memory){
        return s.campaignsById[campaignId];
    }
    // use the zero address if no _referrer
    function becomeAffiliate (address _referrer) external {
        // get lock address from campaign
        address _lockAddress = _getCampaignLockAddress();
        // check if user has a valid key
        require(IPublicLockV12(_lockAddress).getHasValidKey(msg.sender), "No valid key");
        // check if user is already an affiliate
        require(isAffiliate[msg.sender] == false, "Already an Affiliate");
        _setIsAffiliate(msg.sender, true);
        // set new affiliate data
        AffiliateInfo memory _newAffiliate;
        _newAffiliate.campaignId = campaignId;
        _newAffiliate.affiliateId = msg.sender;
        _newAffiliate.referrer = _referrer;
        _updateAffiliateStorage(_newAffiliate, _referrer, true);
        emit NewAffiliate(msg.sender, campaignId);
    }

    // commission is expressed in basis points (ie 100% is 10000, 10% is 1000, 1% is 100)
    function setTiersCommission(address _lockAddress, uint256[] memory _tiersCommission) external {
        CampaignStorage storage _storage = LibCampaignStorage.diamondStorage();
        CampaignInfo memory _campaign = _storage.lockTocampaign[_lockAddress][campaignId];
        require(_campaign.tiersCommission.length == _tiersCommission.length, "Number of tiers mismatch");
        require(_campaign.owner == msg.sender, "Not Campaign owner");
        for (uint256 i = 0; i < _campaign.tiersCommission.length; i++) {
            _campaign.tiersCommission[i] = _tiersCommission[i];
        }
        _storage.lockTocampaign[_lockAddress][campaignId] = _campaign;
        // emit commision set
    }

    function setName(string memory _newName) external {
        CampaignInfo memory _campaign = s.campaignsById[campaignId];
        _campaign.name = _newName;
        s.campaignsById[campaignId] = _campaign;
    }
    /**
     * Price is the same for everyone... 
     * but we fail if signer of data does not match the lock's password.
     */
    function keyPurchasePrice(
        address, /* from */
        address,
        address, /* referrer */
        bytes calldata /* data */
    ) external virtual view returns (uint256 minKeyPrice) {
        minKeyPrice = IPublicLockV12(msg.sender).keyPrice();
    }

    /**
     * No-op but required for the hook to work
     */
    function onKeyPurchase(
        uint256 _tokenId, /* tokenId */
        address, /* from */
        address _recipient, /* recipient */
        address _referrer, /* referrer */
        bytes calldata _data, /* data */
        uint256 _keyPrice, /* minKeyPrice */
        uint256 /* pricePaid */
    ) external {
        CampaignInfo memory _campaign = s.campaignsById[campaignId];
        // calc campaign's commission balance
        uint256 commission = _calculateCampaignCommission(_referrer, _keyPrice);
        // decode referrer's address from calldata
        address _affiliateAddress = abi.decode(_data, (address));
        if(_affiliateAddress != address(0)) {
            // create new referee data
            RefereeInfo memory _newReferee;
            _newReferee.campaignId = campaignId;
            _newReferee.id = _recipient;
            _newReferee.referrer = _affiliateAddress;
            _newReferee.keyPurchased = _tokenId;
            // update referee storage
            _updateRefereeStorage(_newReferee, _affiliateAddress);
            // update campaign's commission balance
            _campaign.commissionBalance += commission;

            // update affiliate commission balance

            // emit new referee event
            emit NewReferee(campaignId, _recipient, _affiliateAddress, _tokenId);
        }else {
            //update campaign's non-commission balance
            _campaign.nonCommissionBalance += commission;
        }
        return;
    }

    function _getCampaignLockAddress()view private returns(address){
        CampaignStorage storage _storage = LibCampaignStorage.diamondStorage();
        CampaignInfo memory _campaign = _storage.campaignsById[campaignId];
        address _lockAddress = _campaign.lockAddress;
        return _lockAddress;
    }

    function _calculateCampaignCommission(address _referrer, uint256 _keyPrice)private view returns (uint256 commission) {
        uint256 referrerFees = getReferrerFee(_referrer);
        if (referrerFees > 0) {
            commission = (_keyPrice * referrerFees) / 10000;
            return commission;
        }
        return 0;
    }
    
    function _updateAffiliateStorage(AffiliateInfo memory _affiliate, address _referrer, bool _isNewAffiliate) private {
        AffiliateStorage storage _affiliateStorage = LibAffiliateStorage.diamondStorage();
         // if referrer not zero address add new affiliate to referrer's list of referees
        if(_referrer != address(0)) _affiliateStorage.refereesOf[_referrer].push(_affiliate.affiliateId);
        // update this campaign's affiliates
        _affiliateStorage.affiliatesOf[campaignId].push(_affiliate);
        // update campaign's affiliates list
        if(!_isNewAffiliate) {
            for (uint256 i = 0; i < _affiliateStorage.affiliatesOf[campaignId].length; i++) {
                if(_affiliateStorage.affiliatesOf[campaignId][i].affiliateId == _affiliate.affiliateId){
                    _affiliateStorage.affiliatesOf[campaignId][i] = _affiliate;
                }
            }
        } else {
            // add affiliate to campaign's affiliates list
            _affiliateStorage.affiliatesOf[campaignId].push(_affiliate);
            // add affiliate to allAffiliates list
            _affiliateStorage.allAffiliates.push(_affiliate.affiliateId);
        }
    }

    function _updateRefereeStorage(RefereeInfo memory _referee, address _referrer) private {
        RefereeStorage storage _refereeStorage = LibRefereeStorage.diamondStorage();
        // add new referee to referee data mapping
        _refereeStorage.refereeData[_referee.id] = _referee;
        // if referrer not zero address add as the referrer 
        if(_referrer != address(0)) _refereeStorage.referrerOf[_referee.id] = _referrer;
        // update allReferees list
        _refereeStorage.allReferees.push(_referee.id);
        // update campaign's affiliates list
    }

    function _setIsAffiliate(address _account, bool _isAffiliate) private {
        isAffiliate[_account] = _isAffiliate;
    }


}