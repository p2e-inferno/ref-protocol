// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    uint256 feesEthBalance;
    mapping (address => uint) feesTokenBalance;
    uint256 withdrawalFee;
    address membershipLock;
    mapping(address => bool) isAffiliate;
    mapping(address => bool) isReferee;
    address unadusAddress;
}


library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("diamond.storage.LibAppStorage");
        assembly {
            ds.slot := storagePosition
        }
    }
}