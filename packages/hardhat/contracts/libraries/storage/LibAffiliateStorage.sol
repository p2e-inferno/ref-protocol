// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SaleInfo {
    address purchaseToken;
    uint256 commissionAmount;
    uint256 date;
}

struct AffiliateInfo {
    address campaignId;
    address affiliateId;
    address referrer;
    uint256[] soldTokens; // List of tokenIds of sold keys
    uint256[] refereesSoldTokens; // List of tokenIds of keys sold by referees
    mapping(uint256 => SaleInfo) saleData; // Mapping of tokenId to sales info
}

struct AffiliateBalance {
    // campaignId => balance - Total affiliate's sales balance in ETH
    mapping(address => uint256) etherBalance;
    // campaignId => tokenAddress => balance - Keeps track of affiliate's sales balance in tokens
    mapping(address => mapping(address => uint256)) tokenBalance;
}

struct AffiliateStorage {
    // address[] allAffiliates; // Tracks total affiliate across all campaigns.
    mapping(address => mapping(address => address[])) refereesOf; // Keeps track of all customers referred by an affiliate for a specific campaign.
    mapping(address => address[]) affiliatesOf; // Keeps track of all affilates of a campaign.
    mapping(address => mapping(address => AffiliateInfo)) affiliateData; // affiliateData; keeps track of data for a specific affiliate in a campaign: affiliateId => campaignId => AffiliateInfo 
    mapping(address => AffiliateBalance) affiliateBalance; // affiliateId => affiliateBalance - Total affiliate's sales balance in ETH
}

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
