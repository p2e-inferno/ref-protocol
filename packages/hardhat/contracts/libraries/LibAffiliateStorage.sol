// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AffiliateInfo {
    address campaignId;
    address affiliateId;
    address referrer;
    uint256 balance;
}

struct AffiliateStorage {
    // Tracks all affiliate.
    address[] allAffiliates;
    // Keeps track of all customers referred by an affiliate.
    mapping(address => address[]) refereesOf;
    // Keeps track of all affilates of a campaign.
    mapping(address => AffiliateInfo[]) affiliatesOf;
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
