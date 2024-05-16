// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/LibAffiliateStorage.sol";
import "../storage/LibCampaignStorage.sol";
import "../storage/LibRefereeStorage.sol";
import "./AffiliateHelpers.sol";

library CampaignHelpers {
	/**
   * @dev Updates the campaign's payout data after a sale.
   * @param _tokenAddress Address of the token
   * @param _l1Share Affiliate share for level 1 referral
   * @param _l2Share Affiliate share for level 2 referral
   * @param _l3Share Affiliate share for level 3 referral
   * @param _affiliateData Struct containing affiliate's upline data
   */
	function _updateCampaignPayoutData(
		address _tokenAddress,
		uint256 _l1Share,
		uint256 _l2Share,
		uint256 _l3Share,
		AffiliateUplineData memory _affiliateData
	) internal {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		CampaignInfo memory campaign = campaignStorage.campaignsById[
			_affiliateData.campaignId
		];
		require(
			campaign.campaignId == _affiliateData.campaignId,
			"Invalid campaign"
		);
		bool isTokenPurchase = _tokenAddress != address(0);

		// update total campaign commissions balance
		isTokenPurchase
			? campaignStorage.commissionTokenBalance[campaign.campaignId][
				_tokenAddress
			] += _l1Share
			: campaignStorage.commissionEtherBalance[
				campaign.campaignId
			] += _l1Share;
		// update campaign multilevel commission balance
		if (_affiliateData.levelTwoReferrer != address(0)) {
			isTokenPurchase
				? campaignStorage.commissionTokenBalance[campaign.campaignId][
					_tokenAddress
				] += _l2Share
				: campaignStorage.commissionEtherBalance[
					campaign.campaignId
				] += _l2Share;
			if (_affiliateData.levelThreeReferrer != address(0)) {
				isTokenPurchase
					? campaignStorage.commissionTokenBalance[
						campaign.campaignId
					][_tokenAddress] += _l3Share
					: campaignStorage.commissionEtherBalance[
						campaign.campaignId
					] += _l3Share;
			} else {
				isTokenPurchase
					? campaignStorage.nonCommissionTokenBalance[
						campaign.campaignId
					][_tokenAddress] += _l3Share
					: campaignStorage.nonCommissionEtherBalance[
						campaign.campaignId
					] += _l3Share;
			}
		} else {
			// update total campaign non commission balance
			isTokenPurchase
				? campaignStorage.nonCommissionTokenBalance[
					campaign.campaignId
				][_tokenAddress] += (_l2Share + _l3Share)
				: campaignStorage.nonCommissionEtherBalance[
					campaign.campaignId
				] += (_l2Share + _l3Share);
		}
		_updateCampaignStorage(campaign);
	}

	/**
	 * @dev Calculates the total commission from all tiers
	 * @notice Adds up the commission from all tiers
	 * @param _campaign Current campaign data
	 * @return total Returns the total commission
	 */
	function _getTotalTiersCommission(
		CampaignInfo memory _campaign
	) internal pure returns (uint256 total) {
		total = 0;
		for (uint i = 0; i < _campaign.tiersCommission.length; i++) {
			total += _campaign.tiersCommission[i];
		}
		return total;
	}

	/**
	 * @dev Returns campaign data for a specific campaign.
	 * @param _campaignId Id of the campaign
	 * @return campaign Struct containing campaign data
	 */
	function _getCampaignData(
		address _campaignId
	) internal view returns (CampaignInfo memory) {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		return campaignStorage.campaignsById[_campaignId];
	}

	/**
	 * @dev Adds a new campaign to the campaign storage.
	 * @param _campaign Struct containing data of the new campaign
	 */
	function _addCampaign(CampaignInfo memory _campaign)internal {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		// update lockTocampaign mapping
		campaignStorage.lockTocampaign[_campaign.lockAddress][
			_campaign.campaignId
		] = _campaign;
		// update campaignsById mapping
		campaignStorage.campaignsById[_campaign.campaignId] = _campaign;
		// update withdrawal delay mapping
		campaignStorage.withdrawalDelay[_campaign.campaignId] = _campaign.delay;
	}

	/**
	 * @dev Updates campaign storage with new campaign data.
	 * @param _campaign Struct containing updated campaign data
	 */
	function _updateCampaignStorage(CampaignInfo memory _campaign) internal {
		_addCampaign(_campaign);
	}
}
