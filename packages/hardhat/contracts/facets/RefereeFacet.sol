// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// LibDiamond 💎 Allows For Diamond Storage
import "../libraries/LibDiamond.sol";

// LibRentalStorage 💎 Allows For Diamond Storage
import "../libraries/LibRefereeStorage.sol";

// LibAppStorage 📱 Allows For App Storage
import "../libraries/LibAppStorage.sol";

// Structs imported from AppStorage
import "../libraries/LibCampaignStorage.sol";

// Hardhat Console Debugging Easy
import "hardhat/console.sol";


// @title UNADUS 
/// @author Danny Thomx
/// @notice
/// @dev
contract RefereeFacet {
    // Using App Storage
    AppStorage internal appStorage;
    // RefereeStorage internal refereeStorage;


    /// @notice This view function returns the rental status of NFT using tokenID
    /// @dev The tokenID is used to fetch rental details of the NFT from Diamond Storage
    /// @param _referee The tokenID of the NFT to fetch rental status
    /// @return This function returns Rental Information of NFT using Diamond Storage
    function referralOf(address _referee, address _campaignId) external view returns (address) {
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

    function getAllReferees()external view returns (address[] memory) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.allReferees;
    }

}