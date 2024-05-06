// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RefereeInfo {
    address campaignId;
    address id;
    address referrer;
    uint256 keyPurchased; 
}

struct RefereeStorage {
    mapping(address => mapping(address =>  RefereeInfo)) refereeData; // keeps track of all referees for a campaign: referee => campaignId => RefereeInfo
    mapping(address => mapping(address => address)) referrerOf; // Keeps tracks who referred a customer for a specific campaign: referee => campaignId => referrer
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
