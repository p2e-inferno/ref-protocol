// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/LibAffiliateStorage.sol";
import "../storage/LibCampaignStorage.sol";
import "../storage/LibRefereeStorage.sol";
import { CampaignHelpers } from "./CampaignHelpers.sol";

/**
 * @title WithdrawalHelpers
 * @dev Library for managing withdrawals.
 */
library WithdrawalHelpers {
   
   /**
   * @dev Fetches the balance of a creator for a given campaign.
   * @param _campaignId ID of the campaign.
   * @param _tokenAddress Address of the token (zero address for ETH)
   * @return returns the balance.
   */
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


	/**
	 * @dev Calculates and returns the withdrawable balance of an affiliate.
	 * @param affiliateAddress Address of affiliate
	 * @param campaignId ID of the affiliate's campaign
	 * @param _tokenAddress Address of token of the affiliate's campaign
	 * @return totalBalance Total withdrawable balance
	 * @return directSalesTokenIds IDs of tokens sold through direct sales
	 * @return refereesSalesTokenIds IDs of tokens sold by referees
	 */
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

	/**
	 * @dev It estimates the balance and eligible tokens for direct sales
	 * @param affiliateAddress The address identifier for the affiliate
	 * @param campaignId The address identifier for the campaign
	 * @param _tokenAddress The address identifier for the token
	 * @return balance and token IDs 
	 */
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

	/**
	 * @dev Estimates the balance and eligible tokens for referred sales
	 * @param affiliateAddress Address identifier for the affiliate
	 * @param campaignId Address identifier for the campaign
	 * @param _tokenAddress Address identifier for the token
	 * @return balance Accumulated balance
	 * @return eligibleTokenIds Token IDs eligible for the operation
	 */
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
	
	/**
	 * @dev Retrives the available balance for an affiliate in a campaign
	 * @param _campaignId Address identifier for the specific campaign
	 * @param _account Address identifier of the affiliate account
	 * @param _tokenAddress Address identifier for the token
	 * @return availableBalance Current available balance for an affiliate
	 */
	function _getAffiliateAvailableBalance(address _campaignId, address _account, address _tokenAddress) internal view returns(uint256 availableBalance) {
        AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
	    bool isTokenWithdrawal = _tokenAddress != address(0);
		availableBalance = isTokenWithdrawal ? affiliateStorage.affiliateBalance[_account].tokenBalance[_campaignId][_tokenAddress] : affiliateStorage.affiliateBalance[_account].etherBalance[_campaignId];
    }

	/**
	 * @dev Calculates the balance and eligible tokens for an affiliate for a specific campaign
	 * @param _account Account address of the affiliate
	 * @param _campaignId Address identifier for the campaign
	 * @param _tokenAddress Address identifier for the token
	 * @param isDirectSales Status of the sale - is it a direct sale or not
	 * @return Accumulated balance and the array of token IDs
	 */
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
				bool isCashedOut = _isCashedOutToken(_account, tokenId, _campaignId);
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

	/**
	 * @dev Checks if a token has been cashed out by an affiliate
	 * @param _affiliateId Address identifier for the affiliate
	 * @param _tokenId ID of the token to be checked
	 * @param _campaignId Address identifier for the campaign
	 * @return isCashedOut Status whether the token has been cashed out or not
	 */
	function _isCashedOutToken(
		address _affiliateId,
		uint256 _tokenId,
		address _campaignId
	) internal view returns (bool isCashedOut) {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();
		isCashedOut = campaignStorage.cashedOutTokens[_campaignId].isCashedOutToken[_affiliateId][_tokenId];
	}

	/**
	 * @dev Checks if a withdrawal is over the delay limit
	 * @param _saleDate Date of the sale
	 * @param _campaignId Address identifier for the campaign
	 * @return Status whether the current date exceeds the delay limit or not
	 */
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
