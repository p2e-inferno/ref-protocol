// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/LibRefereeStorage.sol";
import "../libraries/LibAffiliateStorage.sol";
import "../libraries/LibCampaignStorage.sol";

// @title UNADUS 
/// @author Dannt Thomx
/// @notice
/// @dev
contract AffiliateFacet {

    function getRefereesOf(address _affiliate, address _campaignId)external view returns(address[] memory) {
        AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        return _storage.refereesOf[_affiliate][_campaignId];
    }

    function getCampaignAffiliates(address _campaignId)external view returns(AffiliateInfo[] memory) {
        AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        return _storage.affiliatesOf[_campaignId];
    }

    function getAffiliate(address _affiliate, address _campaignId) external view returns(AffiliateInfo memory) {
        AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        return _storage.affiliateData[_affiliate][_campaignId];
    }

    function allAffiliates() external view returns(address[] memory) {
            AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        return _storage.allAffiliates;
    }

    // function setSomethingCool(address _campaignId, address _affiliate) external {
    //   AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
    //   AffiliateInfo memory _newCampaign;

    //   _newCampaign.campaignId = _campaignId;
    //   _newCampaign.affiliateId = _affiliate;
    //   _newCampaign.referrer = msg.sender;
    //   _storage.affiliatesOf[_campaignId].push(_newCampaign);
    // }

}