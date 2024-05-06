// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Struct for Information related to a Referred Purchase
 * @dev Holds the necessary information involved in a referred purchase 
 */
struct ReferredPurchaseData {
    /** 
     * @notice Unique identifier for the campaign
     * @dev Used to look up an individual campaign
     */
    address campaignId;
    
    /**
     * @notice ID of the purchased NFT token
     * @dev Provides an identifier for the specific token that was bought
     */
    uint256 tokenId;
    
    /** 
     * @notice Ethereum address of the recipient of the purchased token
     * @dev Allows tracking of the individual who received the purchased NFT
     */
    address recipient;
    
    /** 
     * @notice Ethereum address of the Affiliate
     * @dev Provides reference to the individual/entity that referred the purchase
     */
    address affiliateAddress;
    
    /** 
     * @notice Commission amount for the purchase
     * @dev Value to be distributed via the referral system
     */
    uint256 commission;
    
    /**
     * @notice Ethereum address of the commissioned token
     * @dev Provides information on what token the commission should be paid in
	 * @dev address(0) for ETH purchases
     */
    address tokenAddress; 
}

/**
 * @title Interface for implementing a campaign facet
 * @dev A campaign facet controls aspects of a referral system campaign
 */
interface ICampaignFacet {
    /**
     * @notice Handle a referred purchase
     * @dev Hook for logic to run after a referred purchase
     * @param _purchaseData The data related to the referred purchase
     * @return bool whether the function executed successfully
     */
    function onReferredPurchase(
        ReferredPurchaseData memory _purchaseData
    ) external returns (bool);

    /**
     * @notice Handle a non-referred purchase
     * @dev Hook for logic to run after a non-referred purchase
     * @param _campaignId identifier for looking up campaign
     * @param _commission the commission amount for the purchase
     * @param _tokenAddress the address of the token to pay commission in
     * @return bool whether the function executed successfully
     */
    function onNonReferredPurchase(
        address _campaignId,
        uint256 _commission,
        address _tokenAddress
    ) external returns (bool);
}