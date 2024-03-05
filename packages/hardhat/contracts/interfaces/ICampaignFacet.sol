// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ICampaignFacet {
    function onReferredPurchase(
        address _campaignId,
        uint256 _tokenId,
        address _recipient,
        address _affiliateAddress,
        uint256 _commission
    ) external returns(bool);

    function onNonReferredPurchase(address _campaignId, uint256 _commission ) external returns(bool);
}
