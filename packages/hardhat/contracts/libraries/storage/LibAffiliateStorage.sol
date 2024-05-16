// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SaleInfo 
 * @notice Contains information about each token sale.
 */
struct SaleInfo {
    address purchaseToken;
    uint256 commissionAmount;
    uint256 date;
}

/**
 * @title Affiliate Info
 * @notice Contains affiliated information such as referees, sold tokens and sale data for each affiliate for a campaign.
 */
struct AffiliateInfo {
    address campaignId;
    address affiliateId;
    address referrer;
    uint256[] soldTokens; // List of tokenIds of sold keys
    uint256[] refereesSoldTokens; // List of tokenIds of keys sold by referees
    mapping(uint256 => SaleInfo) saleData; // Mapping of tokenId to sales info
}

/**
 * @title Affiliate Balance
 * @notice Contains individual affiliate's balance information.
 */
struct AffiliateBalance {
    // campaignId => balance - Total affiliate's sales balance in ETH
    mapping(address => uint256) etherBalance;
    // campaignId => tokenAddress => balance - Keeps track of affiliate's sales balance in tokens
    mapping(address => mapping(address => uint256)) tokenBalance;
}

/**
 * @title Affiliate Storage
 * @notice Stores all affiliate related data mappings and mappings to structs.
 */
struct AffiliateStorage {
    mapping(address => mapping(address => address[])) refereesOf; // Keeps track of all customers referred by an affiliate for a specific campaign.
    mapping(address => address[]) affiliatesOf; // Keeps track of all affilates of a campaign.
    mapping(address => mapping(address => AffiliateInfo)) affiliateData; // affiliateData; keeps track of data for a specific affiliate in a campaign: affiliateId => campaignId => AffiliateInfo 
    mapping(address => AffiliateBalance) affiliateBalance; // affiliateId => affiliateBalance - Total affiliate's sales balance in ETH
}

/**
 * @title Affiliate Storage Library
 * @notice Contains function to define storage structure for Affiliate Storage.
 */
library LibAffiliateStorage {
    function diamondStorage() internal pure returns (AffiliateStorage storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("diamond.storage.LibAffiliateStorage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}