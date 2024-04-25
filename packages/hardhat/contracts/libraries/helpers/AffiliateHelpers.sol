// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/LibAffiliateStorage.sol";
import "../storage/LibCampaignStorage.sol";
import "../storage/LibRefereeStorage.sol";
import { CampaignHelpers } from "./CampaignHelpers.sol";

struct AffiliateUplineData {
  address campaignId;
  address affiliateId;
  address levelTwoReferrer;
  address levelThreeReferrer;
}

library AffiliateHelpers {

  /**
   * @dev Handles the calculation and distribution of affiliate payout and updates campaign commission balances
   * @notice Distributes affiliate payouts according to a tiered commission model
   * @param _commission Total commission to distribute
   * @param _campaignId The unique identifier for the campaign
   * @return levelOneShare Commission share for Level 1 referral
   * @return levelTwoShare Commission share for Level 2 referral
   * @return levelThreeShare Commission share for Level 3 referral
   */
  function _calculateAffiliatesPayout(
    uint256 _commission, 
    address _campaignId
  ) 
    view
    internal 
    returns(uint256 levelOneShare, uint256 levelTwoShare, uint256 levelThreeShare)
  {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    CampaignInfo memory campaign = cs.campaignsById[_campaignId];

    uint256 totalTiersCommission = CampaignHelpers._getTotalTiersCommission(campaign);
    levelOneShare = _calculateShare(_commission, campaign.tiersCommission[0], totalTiersCommission);
    levelTwoShare = _calculateShare(_commission, campaign.tiersCommission[1], totalTiersCommission);
    levelThreeShare = _calculateShare(_commission, campaign.tiersCommission[2], totalTiersCommission);

    return (levelOneShare, levelTwoShare, levelThreeShare);
  }

  function _addAffiliateReferee(address _affiliateAddress, address _campaignId, address _referee) internal {
    AffiliateStorage storage _affiliateStorage = LibAffiliateStorage.diamondStorage();
    _affiliateStorage.refereesOf[_affiliateAddress][_campaignId].push(_referee);
  }

  function _getAffiliateData(address _campaignId, address _affiliateAddress) internal view returns (AffiliateInfo storage affiliate){
    AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
    return affiliate = affiliateStorage.affiliateData[_affiliateAddress][_campaignId];
  }

  /**
   * @dev Calculates the share for a particular commission tier
   * @notice Derives share by taking into account the commission and total commission from all tiers
   * @param _commission Total commission to distribute
   * @param _tierCommission Commission for the tier
   * @param _totalTiersCommission Total commission from all tiers
   * @return share Share for the tier
   */
  function _calculateShare(
    uint256 _commission, 
    uint256 _tierCommission, 
    uint256 _totalTiersCommission
  ) 
    public 
    pure 
    returns(uint256 share) 
  {
    return (_commission * _tierCommission) / _totalTiersCommission;
  }

  /**
  * @dev Applies updates to an affiliate's information
  * @param _campaignId The ID of the campaign
  * @param _tokenId The ID of the token sold
  * @param _share The commission share for the affiliate
  * @param _affiliateAddress The address of the affiliate
  * @param _levelTwoReferrer Address of the level two referrer
  * @param _levelThreeReferrer Address of the level three referrer
  */
  function _updateAffiliate(
    address _campaignId, 
    uint256 _tokenId, 
    uint256 _share, 
    address _tokenAddress,
    address _affiliateAddress, 
    address _levelTwoReferrer, 
    address _levelThreeReferrer
    ) private 
  {
    AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
    bool isTokenPurchase = _tokenAddress != address(0);
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].saleData[_tokenId].purchaseToken = _tokenAddress;
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].saleData[_tokenId].commissionAmount = _share;
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].saleData[_tokenId].date = block.timestamp;
    isTokenPurchase ? affiliateStorage.tokenBalance[_affiliateAddress][_tokenAddress] += _share : affiliateStorage.etherBalance[_affiliateAddress] += _share;
    if(_affiliateAddress != _levelTwoReferrer && _affiliateAddress != _levelThreeReferrer) {
      affiliateStorage.affiliateData[_affiliateAddress][_campaignId].soldTokens.push(_tokenId);
    } else {
      affiliateStorage.affiliateData[_affiliateAddress][_campaignId].refereesSoldTokens.push(_tokenId);
    }
  }

  /**
   * @dev Updates details related to an affiliate's sale.
   * @param _tokenId The ID of the token being sold
   * @param _share The affiliate's share of the sale
   * @param _affiliateData Struct containing affiliate's upline data
   */
  function _updateAffiliateStorage(
    uint256 _tokenId, 
    uint256 _share, 
    address _tokenAddress,
    address _affiliateToUpdate,
    AffiliateUplineData memory _affiliateData
    ) internal 
  {
    _updateAffiliate(_affiliateData.campaignId, _tokenId, _share, _tokenAddress, _affiliateToUpdate, _affiliateData.levelTwoReferrer, _affiliateData.levelThreeReferrer);
  }

}