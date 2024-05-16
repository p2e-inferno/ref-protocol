// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/storage/LibRefereeStorage.sol";
import "../libraries/storage/LibAppStorage.sol";


// @title Referee Facet 
/// @author Danny Thomx
/// @notice This contract manages referees in the UNADUS protocol 
contract RefereeFacet {
  
    /// @notice This function returns the referrer of a referee in a specific campaign.
    /// @param _referee The address of the referee.
    /// @param _campaignId The address identifier of the campaign.
    /// @return The address of the referrer of the referee in the campaign.
    function referrerOf(address _referee, address _campaignId) external view returns (address) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.referrerOf[_referee][_campaignId];
    }

    /// @notice This function returns data about a referee in a specific campaign.
    /// @param _referee The address of the referee.
    /// @param _campaignId The address identifier of the campaign.
    /// @return RefereeInfo data structure with information about the referee in the specified campaign.
    function getRefereeData(address _referee, address _campaignId) external view returns (RefereeInfo memory) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.refereeData[_referee][_campaignId];
    }
    
    /// @notice This function checks if an account is a referee.
    /// @param _account The address of the account.
    /// @return True if the account is a referee, false otherwise.
    function getIsReferee(address _account)external view returns (bool) {
      AppStorage storage _storage = LibAppStorage.diamondStorage();
      return _storage.isReferee[_account];
    }

}