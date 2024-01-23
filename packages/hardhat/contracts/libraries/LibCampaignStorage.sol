// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppConstants.sol";

struct CampaignInfo {
    string name;
    address campaignId;
    address owner;
    // NFT contract address
    address lockAddress;
    // Commission per level (e.g., [5, 2, 1] - 5% for level 1, 2% for level 2, 1% for level 3)
    uint[] tiersCommission;
    uint256 commissionBalance;
    uint256 nonCommissionBalance;
}

struct CampaignStorage {
    // maps lock (address) to campaignId (address) for a specific campaign
    mapping(address => mapping(address => CampaignInfo)) lockTocampaign;
    // maps a campaignId to a campaign
    mapping(address => CampaignInfo) campaignsById;
    CampaignInfo[] allCampaigns;
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
