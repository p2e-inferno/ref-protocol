// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/LibAffiliateStorage.sol";
import "../storage/LibCampaignStorage.sol";
import "../storage/LibRefereeStorage.sol";
import { CampaignHelpers } from "./CampaignHelpers.sol";

library WithdrawalHelpers {

	function _fetchCreatorBalance(
		address _campaignId,
		address _tokenAddress
	) internal view returns (uint256) {
		bool isTokenBalance = _tokenAddress != address(0);
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		return
			isTokenBalance
				? campaignStorage.nonCommissionTokenBalance[_campaignId][
					_tokenAddress
				]
				: campaignStorage.nonCommissionEtherBalance[_campaignId];
	}

	function _calculateAffiliateWithdrawableBalance(
		address affiliateAddress,
		address campaignId,
        address _tokenAddress
	)
		internal
		view
		returns (
			uint256 totalBalance,
			uint256[] memory directSalesTokenIds,
			uint256[] memory refereesSalesTokenIds
		)
	{
		(
			uint256 directSalesCommission,
			uint256[] memory _directSalesTokenIds
		) = _estimateBalanceAndEligibleTokensForDirectSales(
				affiliateAddress,
				campaignId,
                _tokenAddress
			);
		(
			uint256 referredSalesCommission,
			uint256[] memory _refereesSalesTokenIds
		) = _estimateBalanceAndEligibleTokensForReferredSales(
				affiliateAddress,
				campaignId,
                _tokenAddress
			);
		totalBalance = directSalesCommission + referredSalesCommission;
		directSalesTokenIds = _directSalesTokenIds;
		refereesSalesTokenIds = _refereesSalesTokenIds;
		return (totalBalance, directSalesTokenIds, refereesSalesTokenIds);
	}

	function _estimateBalanceAndEligibleTokensForDirectSales(
		address affiliateAddress,
		address campaignId,
        address _tokenAddress
	)
		internal
		view
		returns (uint256 balance, uint256[] memory eligibleTokenIds)
	{
		return
			_calculateBalanceAndEligibleTokens(
				affiliateAddress,
				campaignId,
                _tokenAddress,
				true
			);
	}

	function _estimateBalanceAndEligibleTokensForReferredSales(
		address affiliateAddress,
		address campaignId,
        address _tokenAddress
	)
		internal
		view
		returns (uint256 balance, uint256[] memory eligibleTokenIds)
	{
		return
			_calculateBalanceAndEligibleTokens(
				affiliateAddress,
				campaignId,
                _tokenAddress,
				false
			);
	}

	function _calculateBalanceAndEligibleTokens(
		address _account,
		address _campaignId,
        address _tokenAddress,
		bool isDirectSales
	) internal view returns (uint256, uint256[] memory) {
		AffiliateStorage storage affiliateStorage = LibAffiliateStorage
			.diamondStorage();
		AffiliateInfo storage affiliate = affiliateStorage.affiliateData[
			_account
		][_campaignId];
		// Choose the correct array depending on isDirectSales
		uint256[] memory tokensArray = isDirectSales
			? affiliate.soldTokens
			: affiliate.refereesSoldTokens;
		uint256 balance = 0;
		uint256[] memory tokensToCashOut = new uint256[](tokensArray.length); // Initialize tokensToCashOut with the same length as tokensArray
		if (tokensArray.length > 0) {
			for (uint256 i = 0; i < tokensArray.length; i++) {
				uint256 tokenId = tokensArray[i];
				bool isCashedOut = _isCashedOutToken(tokenId, _campaignId);
				SaleInfo memory saleInfo = affiliate.saleData[tokenId];
				if (
					_isOverWithdrawalDelay(saleInfo.date, _campaignId) &&
					!isCashedOut &&
                    saleInfo.purchaseToken == _tokenAddress
				) {
					balance += saleInfo.commissionAmount;
					tokensToCashOut[i] = tokenId;
				}
			}
		}
		return (balance, tokensToCashOut);
	}

	function _isCashedOutToken(
		uint256 _tokenId,
		address _campaignId
	) internal view returns (bool isCashedOut) {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		isCashedOut = campaignStorage.isCashedOutToken[_campaignId][_tokenId];
	}

	function _isOverWithdrawalDelay(
		uint256 _saleDate,
		address _campaignId
	) internal view returns (bool) {
        CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		CampaignInfo memory campaign = campaignStorage.campaignsById[_campaignId];
		uint256 _currentDate = block.timestamp;
		uint256 secondsInDay = 1 days;
		uint256 withdrawalDelay = campaign.delay * secondsInDay;
		return _currentDate > (_saleDate + withdrawalDelay);
	}
}
