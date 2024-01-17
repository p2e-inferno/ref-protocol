// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppConstants.sol";

struct CampaignInfo {
    address campaignId;
    address owner;
    // NFT contract address
    address nftAddress;
    // Commission per level (e.g., [5, 2, 1] - 5% for level 1, 2% for level 2, 1% for level 3)
    uint[3] commissionRate;
}

struct CampaignStorage {
    mapping(address => CampaignInfo) nftTocampaign;
    CampaignInfo[] campaigns;
}

library LibCampaignStorage {
    function diamondStorage() internal pure returns (CampaignStorage storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("diamond.storage.LibCampaignStorage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }


}
