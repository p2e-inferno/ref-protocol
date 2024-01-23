// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RefereeInfo {
    address campaignId;
    address id;
    address referrer;
    uint256 keyPurchased; 
}

struct RefereeStorage {
    mapping(address => RefereeInfo) refereeData; 
    // This tracks who referred a customer
    mapping(address => address) referrerOf;
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
