// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/storage/LibAppStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Contract Modifiers
 * @dev Establishes common modifiers for use across multiple contracts
 */
abstract contract Modifiers {
  /**
   * @notice Ensures a function can only be called by the owner of Unadus
   * @dev Checks if the sender is the owner of Unadus contract
   */
  modifier onlyOwner() {
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    require(appStorage.unadusAddress != address(0), "UNADUS not Initialized");
    require(IERC173(appStorage.unadusAddress).owner() == msg.sender, "Not Owner");
    _;
  }

  /**
   * @notice Ensures a function can only be called by the owner of a campaign
   * @dev Checks if the sender is the owner of a specific campaign ID
   * @param _campaignId The ID of the campaign
   */
  modifier onlyCampaignOwner(address _campaignId) {
    CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
    CampaignInfo memory _campaign = campaignStorage.campaignsById[_campaignId];
    require(_campaign.owner == msg.sender, "Not Campaign owner");
    _;
  }

  /**
   * @notice Ensures a function can only be called if Unadus has sufficient token balance
   * @dev Checks if the Unadus contract has sufficient balance of a specific token
   * @param _amount The amount of tokens needed
   * @param _tokenAddress The address of the token 
   */
  modifier onlySufficientTokenBalance(uint256 _amount, address _tokenAddress) {
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    address unadus = appStorage.unadusAddress;
    require(_tokenAddress != address(0), "Invalid token address");
    require(IERC20(_tokenAddress).balanceOf(unadus) >= _amount, "Token::Insufficient Contract balance");
    _;
  }

  /**
   * @notice Ensures a function can only be called by registered campaign contracts
   * @dev Checks if the sender is a registered campaign contract
   */
  modifier onlyCampaign () {
    CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
    require(campaignStorage.isCampaign[msg.sender], "Only Campaign Hook Allowed");
    _;
  }
}