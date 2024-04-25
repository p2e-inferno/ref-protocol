// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ReferredPurchaseData {
	address campaignId;
	uint256 tokenId;
	address recipient;
	address affiliateAddress;
	uint256 commission;
	address tokenAddress;
}

interface ICampaignFacet {
	function onReferredPurchase(
		ReferredPurchaseData memory _purchaseData
	) external returns (bool);

	function onNonReferredPurchase(
		address _campaignId,
		uint256 _commission,
		address _tokenAddress
	) external returns (bool);
}
