// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CampaignInfo 
 * @notice Contains all necessary variables and data for a campaign.
 */
struct CampaignInfo {
    string name;
    address campaignId;
    address owner;
    address lockAddress;  // NFT contract address
    uint[] tiersCommission; // Commission per level in basis points, e.g., [5000, 2000, 1000] representing 5% for level 1, 2% for level 2, 1% for level 3
    uint256 delay;
}

/**
 * @title CashedOutTokens 
 * @notice A struct to keep record of Tokens that have been cashed out.
 */
struct CashedOutTokens {
   mapping(address => mapping(uint => bool)) isCashedOutToken; // Mapping to record whether an affiliate's commission for a specific tokenId has been cashed out
}

/**
 * @title CampaignStorage 
 * @notice Contains all necessary mappings for storing campaign related info.
 */
struct CampaignStorage {
    mapping(address => mapping(address => CampaignInfo)) lockTocampaign; // Maps an NFT contract address to campaignId for a specific campaign
    mapping(address => CampaignInfo) campaignsById; // Maps a campaignId to CampaignInfo struct
    mapping(address => uint) withdrawalDelay; // Tracks the withdrawal delay for each campaign
    mapping(address => CashedOutTokens) cashedOutTokens; // CampaignId => CashedOutTokens struct that tracks whether an affiliate's commission for a tokenId in a specific campaign has been cashed out
    mapping(address => uint256) commissionEtherBalance; // Records the total Ether balance from commissions for a campaign
    mapping(address => uint256) nonCommissionEtherBalance; // Records the total Ether balance from purchases without commission for a campaign
    mapping(address => mapping(address => uint256)) commissionTokenBalance; // Records the total token balance from commissions for a  campaign
    mapping(address => mapping(address => uint256)) nonCommissionTokenBalance; // Records the total token balance from purchases without commission for a campaign
    mapping(address => address) lockToCampaignId; // Records the mapping of an NFT contract address to a campaignId
    mapping(address => bool) isCampaign; // Records if an address is a registered campaign
}

/**
 * @title Campaign Storage Library
 * @notice Contains function that define storage structure for Campaign Storage.
 */
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