// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibAffiliateStorage.sol";
import "./LibCampaignStorage.sol";
import "./LibRefereeStorage.sol";

struct AffiliateUplineData {
    address campaignId;
    address affiliateId;
    address levelTwoReferrer;
    address levelThreeReferrer;
}

library Utilities {

  function _getMultiLevelReferrers(address _levelOneReferrerAddress, address _campaignId) view internal returns(address, address) {
    RefereeStorage storage refereeStorage = LibRefereeStorage.diamondStorage();
    address levelTwoReferrer = refereeStorage.referrerOf[_levelOneReferrerAddress][_campaignId];
    address levelThreeReferrer = refereeStorage.referrerOf[levelTwoReferrer][_campaignId];
    return (levelTwoReferrer, levelThreeReferrer);
  }

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

    uint256 totalTiersCommission = _getTotalTiersCommission(campaign);
    levelOneShare = _calculateShare(_commission, campaign.tiersCommission[0], totalTiersCommission);
    levelTwoShare = _calculateShare(_commission, campaign.tiersCommission[1], totalTiersCommission);
    levelThreeShare = _calculateShare(_commission, campaign.tiersCommission[2], totalTiersCommission);

    return (levelOneShare, levelTwoShare, levelThreeShare);
  }

  function _updateCampaignPayoutData(uint256 _l1Share, uint256 _l2Share, uint256 _l3Share, AffiliateUplineData memory _affiliateData) internal {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    CampaignInfo memory campaign = cs.campaignsById[_affiliateData.campaignId];
    require(campaign.campaignId == _affiliateData.campaignId, "Invalid campaign");
    
    // update campaign commission balance
    campaign.commissionBalance += _l1Share;
    // update campaign non commission balance
    if(_affiliateData.levelTwoReferrer != address(0)){
      campaign.commissionBalance += _l2Share;
      if(_affiliateData.levelThreeReferrer != address(0)){
        campaign.commissionBalance += _l3Share;
      }else{
        campaign.nonCommissionBalance += _l3Share;
      }
    }else{
      campaign.nonCommissionBalance += (_l2Share + _l3Share);
    }
    _updateCampaignStorage(campaign);
  }

  function _addAffiliateReferee(address _affiliateAddress, address _campaignId, address _referee) internal {
    AffiliateStorage storage _affiliateStorage = LibAffiliateStorage.diamondStorage();
    _affiliateStorage.refereesOf[_affiliateAddress][_campaignId].push(_referee);
  }

  /**
   * @dev Calculates the total commission from all tiers
   * @notice Adds up the commission from all tiers
   * @param _campaign Current campaign data
   * @return total Returns the total commission
   */
  function _getTotalTiersCommission(CampaignInfo memory _campaign) internal pure returns(uint256 total){
    total = 0;
    for(uint i = 0; i < _campaign.tiersCommission.length; i++) {
      total += _campaign.tiersCommission[i];
    }
    return total;
  }

  function _getCampaignData(address _campaignId) internal view returns (CampaignInfo memory){
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    return cs.campaignsById[_campaignId];
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

  function _fetchCreatorBalance(address _campaignId)view internal returns(uint256) {
    CampaignInfo memory campaign = _getCampaignData(_campaignId);
    return campaign.nonCommissionBalance;
  }

  function _calculateAffiliateWithdrawableBalance(address affiliateAddress, address campaignId) 
    internal 
    view 
    returns (uint256 totalBalance, uint256[] memory directSalesTokenIds, uint256[] memory refereesSalesTokenIds) 
  {
    (uint256 directSalesCommission, uint256[] memory _directSalesTokenIds) = _estimateBalanceAndEligibleTokensForDirectSales(affiliateAddress, campaignId);
    (uint256 referredSalesCommission, uint256[] memory _refereesSalesTokenIds) = _estimateBalanceAndEligibleTokensForReferredSales(affiliateAddress, campaignId);
    totalBalance = directSalesCommission + referredSalesCommission;
    directSalesTokenIds = _directSalesTokenIds;
    refereesSalesTokenIds = _refereesSalesTokenIds;
    return (totalBalance, directSalesTokenIds, refereesSalesTokenIds);
  }

  function _estimateBalanceAndEligibleTokensForDirectSales(address affiliateAddress, address campaignId) 
    internal 
    view 
    returns (uint256 balance, uint256[] memory eligibleTokenIds) 
  {
    return _calculateBalanceAndEligibleTokens(affiliateAddress, campaignId, true);
  }

  function _estimateBalanceAndEligibleTokensForReferredSales(address affiliateAddress, address campaignId) 
    internal 
    view 
    returns (uint256 balance, uint256[] memory eligibleTokenIds) 
  {
    return _calculateBalanceAndEligibleTokens(affiliateAddress, campaignId, false);
  }

  function _calculateBalanceAndEligibleTokens(address _account, address _campaignId, bool isDirectSales) 
    internal 
    view 
    returns(uint256, uint256[] memory) 
  {
    AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
    AffiliateInfo storage affiliate = affiliateStorage.affiliateData[_account][_campaignId];
    // Choose the correct array depending on isDirectSales
    uint256[] memory tokensArray = isDirectSales ? affiliate.soldTokens : affiliate.refereesSoldTokens;
    uint256 balance = 0;
    uint256[] memory tokensToCashOut;
    if(tokensArray.length > 0){
      for(uint256 i = 0; i < tokensArray.length; i++){
        uint256 tokenId = tokensArray[i];
        bool isCashedOut = _isCashedOutToken(tokenId, _campaignId);
        SaleInfo memory saleInfo = affiliate.saleData[tokenId];
        if(_isOverWithdrawalDelay(saleInfo.date, _campaignId) && isCashedOut == false) {
          balance += saleInfo.commissionAmount;
          tokensToCashOut[i] = tokenId;
        }
      }
    }
    return (balance, tokensToCashOut);
  }

  function _isCashedOutToken(uint256 _tokenId, address _campaignId)internal view returns (bool isCashedOut){
    CampaignStorage storage _campaignStorage = LibCampaignStorage.diamondStorage();
    isCashedOut = _campaignStorage.isCashedOutToken[_campaignId][_tokenId];
  }

  function _isOverWithdrawalDelay(uint256 _saleDate, address _campaignId) view internal returns(bool){
    CampaignInfo memory campaign = _getCampaignData(_campaignId);
    uint256 _currentDate = block.timestamp;
    uint256 secondsInDay = 1 days;
    uint256 withdrawalDelay = campaign.delay * secondsInDay;
    return _currentDate > (_saleDate + withdrawalDelay);
  }

  function _updateCampaignStorage(CampaignInfo memory _campaign) internal {
    CampaignStorage storage _campaignStorage = LibCampaignStorage.diamondStorage();
    // update lockTocampaign mapping
    _campaignStorage.lockTocampaign[_campaign.lockAddress][_campaign.campaignId] = _campaign;
    // update campaignsById mapping
    _campaignStorage.campaignsById[_campaign.campaignId] = _campaign;
    // update withdrawal delay mapping
    _campaignStorage.withdrawalDelay[_campaign.campaignId] = _campaign.delay;

    // update _campaign in allCampaigns list
    CampaignInfo[] memory allCampaigns = _campaignStorage.allCampaigns;
    uint256 index;
    for (index = 0; index < allCampaigns.length; index++) {
        if(allCampaigns[index].campaignId == _campaign.campaignId) allCampaigns[index] = _campaign;
    }
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
    address _affiliateAddress, 
    address _levelTwoReferrer, 
    address _levelThreeReferrer
    ) internal 
  {
    AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].saleData[_tokenId].commissionAmount = _share;
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].saleData[_tokenId].date = block.timestamp;
    affiliateStorage.affiliateData[_affiliateAddress][_campaignId].balance += _share;
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
    address _affiliateToUpdate,
    AffiliateUplineData memory _affiliateData
    ) internal 
  {
    _updateAffiliate(_affiliateData.campaignId, _tokenId, _share, _affiliateToUpdate, _affiliateData.levelTwoReferrer, _affiliateData.levelThreeReferrer);
  }

}