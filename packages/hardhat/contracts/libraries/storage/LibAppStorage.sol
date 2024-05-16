// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AppStorage 
 * @notice Contains all necessary variables and mappings for the application.
 */
struct AppStorage {
    uint256 feesEthBalance;
    mapping (address => uint) feesTokenBalance;
    uint256 withdrawalFee;
    address membershipLock;
    mapping(address => bool) isAffiliate; // Keeps track of all registered affiliates
    mapping(address => bool) isReferee; // Keeps track of all registered referees
    address unadusAddress;
}

/**
 * @title App Storage Library
 * @notice Contains function to define storage structure for App Storage.
 */
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("diamond.storage.LibAppStorage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}