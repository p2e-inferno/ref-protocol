// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibCampaignStorage.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "./Campaign.sol";

// @title UNADUS 
/// @author Dannt Thomx
/// @notice
/// @dev
contract CampaignFacet {

  // mapping of lock address to campaign Ids
  mapping(address => address) public affiliateCampaigns;

  event NewCampaign(address campaignId, address owner, address nftAddress, uint256[] commissionRate);

  function _isLockManager(address _lockAddress)
    internal
    view
    returns (bool isManager)
  {
    isManager = IPublicLockV12(_lockAddress).isLockManager(msg.sender);
  }

  function getMaxTiers() external pure returns(uint){
    return AppConstants.MAX_TIERS;
  }

  function createCampaign(string memory _name, address _lockAddress, uint256[] memory _affiliateCommission) external {
      require(
          affiliateCampaigns[_lockAddress] == address(0),
          "Campaign exist for this lock"
      );
      require(_isLockManager(_lockAddress), "Not Lock Manager");
      require(_affiliateCommission.length <= AppConstants.MAX_TIERS, "Exceeds Maximum Tiers");
      CampaignStorage storage _campaignStorage = LibCampaignStorage.diamondStorage();
      CampaignInfo memory _newCampaign;
      // deploy campaign (onKeyPurchase) hook to track purchases for campaign 
      CampaignHook newCampaignId = new CampaignHook();
      // create new campaign
      _newCampaign.name = _name;
      _newCampaign.campaignId = address(newCampaignId);
      _newCampaign.tiersCommission = _affiliateCommission;
      _newCampaign.owner = msg.sender;
      _newCampaign.lockAddress = _lockAddress;
      // update affiliateCampaigns mapping for this lock
      affiliateCampaigns[_lockAddress] = address(newCampaignId);
      // update campaign storage
      _campaignStorage.lockTocampaign[_lockAddress][address(newCampaignId)] = _newCampaign;
      _campaignStorage.campaignsById[address(newCampaignId)] = _newCampaign;
      _campaignStorage.allCampaigns.push(_newCampaign);
      // set campaignId as onKeyPurchaseHook for the lock
      IPublicLockV12(_lockAddress).setEventHooks(address(newCampaignId), address(0),address(0),address(0),address(0),address(0),address(0));
      // emit NewCampaign event
      emit NewCampaign(address(newCampaignId), msg.sender, _lockAddress, _affiliateCommission);
  }

  function getCampaign( address _lockAddress) external view returns (CampaignInfo memory) {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    require(affiliateCampaigns[_lockAddress] != address(0), "No campaign exist for this lock");
    address campaignId = affiliateCampaigns[_lockAddress];
    return cs.campaignsById[campaignId];
  }

}