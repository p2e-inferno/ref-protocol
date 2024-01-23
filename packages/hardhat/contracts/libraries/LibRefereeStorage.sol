// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RefereeInfo {
    address campaignId;
    address id;
    address referrer;
    uint256 keyPurchased; 
}

struct RefereeStorage {
    // keeps track of all referees for a campaign
    // maps referee => campaignId => RefereeInfo
    mapping(address => mapping(address =>  RefereeInfo)) refereeData;
    // Keeps tracks who referred a customer for a specific campaign.
    // maps referee => campaignId => referrer
    mapping(address => mapping(address => address)) referrerOf;
    // This tracks all referred customers
    address[] allReferees;
}

library LibRefereeStorage {
    function diamondStorage() internal pure returns (RefereeStorage storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("diamond.storage.LibRefereeStorage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }


}
