// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppConstants.sol";

struct AppStorage {
    uint256 feesBalance;
    uint256 withdrawalFee;
    address membershipLock;
    
    // This tracks the customers that an affiliate (referrer) referred
    // mapping(address => address[]) referralsOf;

    // This tracks the total referral commission of an affiliate (referrer)
    // mapping(address => uint) commissionOf;
    
    mapping(address => bool) isAffiliate;
    mapping(address => bool) isReferee;
}


library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}