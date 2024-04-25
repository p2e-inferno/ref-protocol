// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/storage/LibAppStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Modifiers {
  modifier onlyOwner() {
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    require(appStorage.unadusAddress != address(0), "UNADUS not Initialized");
    require(IERC173(appStorage.unadusAddress).owner() == msg.sender, "Not Owner");
    _;
  }

  modifier onlyCampaignOwner(address _campaignId) {
    CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
    CampaignInfo memory _campaign = campaignStorage.campaignsById[_campaignId];
    require(_campaign.owner == msg.sender, "Not Campaign owner");
    _;
  }

  modifier onlySufficientTokenBalance(uint256 _amount, address _tokenAddress) {
    AppStorage storage appStorage = LibAppStorage.diamondStorage();
    address unadus = appStorage.unadusAddress;
    require(_tokenAddress != address(0), "Invalid token address");
    require(IERC20(_tokenAddress).balanceOf(unadus) >= _amount, "Token::Insufficient Contract balance");
    _;
  }

  modifier onlyCampaign () {
    CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
    require(campaignStorage.isCampaign[msg.sender], "Only Campaign Hook Allowed");
    _;
  }
}