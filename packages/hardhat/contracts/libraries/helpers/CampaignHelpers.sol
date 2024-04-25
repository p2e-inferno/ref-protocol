// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/LibAffiliateStorage.sol";
import "../storage/LibCampaignStorage.sol";
import "../storage/LibRefereeStorage.sol";
import "./AffiliateHelpers.sol";

library CampaignHelpers {

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

	function _getCampaignData(
		address _campaignId
	) internal view returns (CampaignInfo memory) {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		return campaignStorage.campaignsById[_campaignId];
	}

	function _addCampaign(CampaignInfo memory _campaign, bool _isUpdateOperation)internal {
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
		if(_isUpdateOperation){
			CampaignInfo[] memory allCampaigns = campaignStorage.allCampaigns;
			uint256 index;
			for (index = 0; index < allCampaigns.length; index++) {
				if (allCampaigns[index].campaignId == _campaign.campaignId)
					allCampaigns[index] = _campaign;
			}
		}else {
			campaignStorage.allCampaigns.push(_campaign);
		}
	}

	function _updateCampaignStorage(CampaignInfo memory _campaign) internal {
		_addCampaign(_campaign, true);
	}
}
