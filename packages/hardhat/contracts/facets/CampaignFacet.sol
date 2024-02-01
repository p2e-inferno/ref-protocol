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
  mapping(address => address) public lockToCampaignId;

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

  // function createCampaign(string memory _name, address _lockAddress, uint256 _level1Commission, uint256 _level2Commission, uint256 _level3Commission) external {
  //     require(
  //         lockToCampaignId[_lockAddress] == address(0),
  //         "Campaign exist for this lock"
  //     );
  //     require(_isLockManager(_lockAddress), "Not Lock Manager");
  //     // require(_affiliateCommission.length <= AppConstants.MAX_TIERS, "Exceeds Maximum Tiers");
  //     CampaignStorage storage _campaignStorage = LibCampaignStorage.diamondStorage();
  //     CampaignInfo memory _newCampaign;
  //       uint256[] memory tiersCommission = new uint256[](3);
  //     tiersCommission[0] = _level1Commission;
  //     tiersCommission[1] = _level2Commission;
  //     tiersCommission[2] = _level3Commission;
  //     // deploy campaign (onKeyPurchase) hook to track purchases for campaign 
  //     CampaignHook newCampaignId = new CampaignHook();
  //     // create new campaign
  //     _newCampaign.name = _name;
  //     _newCampaign.campaignId = address(newCampaignId);
  //     _newCampaign.tiersCommission = tiersCommission;
  //     _newCampaign.owner = msg.sender;
  //     _newCampaign.lockAddress = _lockAddress;
  //     // update lockToCampaignId mapping for this lock
  //     lockToCampaignId[_lockAddress] = address(newCampaignId);
  //     // update campaign storage
  //     _campaignStorage.lockTocampaign[_lockAddress][address(newCampaignId)] = _newCampaign;
  //     _campaignStorage.campaignsById[address(newCampaignId)] = _newCampaign;
  //     _campaignStorage.allCampaigns.push(_newCampaign);
  //     // set campaignId as onKeyPurchaseHook for the lock
  //     // IPublicLockV12(_lockAddress).setEventHooks(address(newCampaignId), address(0),address(0),address(0),address(0),address(0),address(0));
  //     // emit NewCampaign event
  //     emit NewCampaign(address(newCampaignId), msg.sender, _lockAddress, tiersCommission);
  // }

  // function createCampaign(string memory _name, address newCampaignId, address _lockAddress, uint256 _level1Commission, uint256 _level2Commission, uint256 _level3Commission) external {
  function createCampaign(string memory _name, address _lockAddress, uint256 _level1Commission, uint256 _level2Commission, uint256 _level3Commission) external {
      require(
          lockToCampaignId[_lockAddress] == address(0),
          "Campaign exist for this lock"
      );
      require(_isLockManager(_lockAddress), "Not Lock Manager");
      CampaignStorage storage _campaignStorage = LibCampaignStorage.diamondStorage();
      CampaignInfo memory _newCampaign;
      uint256[] memory tiersCommission = new uint256[](3);
      tiersCommission[0] = _level1Commission;
      tiersCommission[1] = _level2Commission;
      tiersCommission[2] = _level3Commission;
      // deploy campaign (onKeyPurchase) hook to track purchases for campaign 
      CampaignHook newCampaignId = new CampaignHook();
      // create new campaign
      _newCampaign.name = _name;
      _newCampaign.campaignId = address(newCampaignId);
      _newCampaign.tiersCommission = tiersCommission;
      _newCampaign.owner = msg.sender;
      _newCampaign.lockAddress = _lockAddress;
      // update lockToCampaignId mapping for this lock
      lockToCampaignId[_lockAddress] = address(newCampaignId);
      // update campaign storage
      _campaignStorage.lockTocampaign[_lockAddress][address(newCampaignId)] = _newCampaign;
      _campaignStorage.campaignsById[address(newCampaignId)] = _newCampaign;
      _campaignStorage.allCampaigns.push(_newCampaign);
      // set campaignId as onKeyPurchaseHook for the lock
      IPublicLockV12(_lockAddress).setEventHooks(address(newCampaignId), address(0),address(0),address(0),address(0),address(0),address(0));

     // emit NewCampaign event
      emit NewCampaign(address(newCampaignId), msg.sender, _lockAddress, tiersCommission);
  }

  function getCampaignForLock( address _lockAddress) external view returns (CampaignInfo memory) {
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    require(lockToCampaignId[_lockAddress] != address(0), "No campaign exist for this lock");
    address campaignId = lockToCampaignId[_lockAddress];
    return cs.campaignsById[campaignId];
  }

  function getCampaignData(address _campaignId) external view returns (CampaignInfo memory){
    CampaignStorage storage cs = LibCampaignStorage.diamondStorage();
    return cs.campaignsById[_campaignId];
  }

}