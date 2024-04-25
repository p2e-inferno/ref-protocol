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
    // uint256 balance; // Total affiliate's sales balance
    uint256[] soldTokens; // List of tokenIds of sold keys
    uint256[] refereesSoldTokens; // List of tokenIds of keys sold by referees
    mapping(uint256 => SaleInfo) saleData; // Mapping of tokenId to sales info
}
    

struct AffiliateStorage {
    // Tracks all affiliate.
    address[] allAffiliates;
    // Keeps track of all customers referred by an affiliate for a specific campaign.
    mapping(address => mapping(address => address[])) refereesOf;
    // Keeps track of all affilates of a campaign.
    mapping(address => address[]) affiliatesOf;
    /**************************************************
    * keeps track of data for a specific affiliate in a campaign
    * Maps affiliateId => campaignId => AffiliateInfo 
    **************************************************/
    mapping(address => mapping(address => AffiliateInfo)) affiliateData; 
    mapping(address => uint256) etherBalance; // Total affiliate's sales balance in ETH
    mapping(address => mapping(address => uint256)) tokenBalance; // Keeep track of affiliate's sales balance in tokens
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
