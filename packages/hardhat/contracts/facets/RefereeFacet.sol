// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/storage/LibRefereeStorage.sol";
import "../libraries/storage/LibAppStorage.sol";

// @title UNADUS 
/// @author Danny Thomx
/// @notice

contract RefereeFacet {
  
    /// @notice This view function returns the rental status of NFT using tokenID
    /// @dev The tokenID is used to fetch rental details of the NFT from Diamond Storage
    /// @param _referee The tokenID of the NFT to fetch rental status
    /// @return This function returns Rental Information of NFT using Diamond Storage
    function referrerOf(address _referee, address _campaignId) external view returns (address) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.referrerOf[_referee][_campaignId];
    }

    /// @notice This view function returns all NFTs listed in rental marketplace
    /// @dev The function loops through all the NFTs the contract owns and checks the rental status using Diamond Storage
    /// @return This function returns 3 arrays -> first array contains the Chararacter Attributes of NFTs; second array contains the Rental Information of NFTs; third array contains the tokenIDs of NFTs
    function getRefereeData(address _referee, address _campaignId) external view returns (RefereeInfo memory) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.refereeData[_referee][_campaignId];
    }

    function getIsReferee(address _account)external view returns (bool) {
      AppStorage storage _storage = LibAppStorage.diamondStorage();
      return _storage.isReferee[_account];
    }

}