// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./storage/LibAffiliateStorage.sol";
import "./storage/LibCampaignStorage.sol";
import "./storage/LibRefereeStorage.sol";
import "./storage/LibAppStorage.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";

/**
 * @title Utilities Library
 * @dev Provides utility functions used across multiple contracts
 */
library Utilities {

    /**
     * @notice Returns Unadus the Membership contract address
     * @dev Fetches the address of the Membership Lock from AppStorage
     * @return Address of the Membership Lock
     */
	function _getMembershipLock() internal view returns (address) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.membershipLock;
	}

    /**
     * @notice Returns the referrers of a specific campaign
     * @dev Fetches the address of Level 2 and Level 3 referrers for a specific campaign
     * @param _levelOneReferrerAddress The address of the first level referrer
     * @param _campaignId The ID of the campaign
     * @return The addresses of the second and third level referrers
     */
    function _getMultiLevelReferrers(address _levelOneReferrerAddress, address _campaignId) view internal returns(address, address) {
		RefereeStorage storage refereeStorage = LibRefereeStorage.diamondStorage();
		address levelTwoReferrer = refereeStorage.referrerOf[_levelOneReferrerAddress][_campaignId];
		address levelThreeReferrer = refereeStorage.referrerOf[levelTwoReferrer][_campaignId];
		return (levelTwoReferrer, levelThreeReferrer);
	}

    /**
     * @notice Checks if the sender is a lock manager of a particular lock
     * @dev Uses the isLockManager method from IPublicLockV12 to verify if the sender is a manager of the lock
     * @param _lockAddress the address of the lock
     * @return isManager value indicating whether the sender is a lock manager or not
     */
	function _isLockManager(address _lockAddress) internal view returns (bool isManager) {
		isManager = IPublicLockV12(_lockAddress).isLockManager(msg.sender);
	}
  
    /**
     * @notice Checks if a user has valid memberbership NFT for Unadus membership contract
     * @dev Uses the getHasValidKey method from IPublicLockV12 to verify if the user has a valid key 
     * @param _user Address of the user to be checked
     * @return _hasValidMembership value indicating whether the user is a member or not
     */
    function _isMember(address _user) 
		internal 
		view returns (bool _hasValidMembership) 
	{
		address membershipLock = _getMembershipLock();
		if (membershipLock == address(0)) return false;
		_hasValidMembership = IPublicLockV12(membershipLock).getHasValidKey(_user);
	}

    /**
     * @notice Updates referee storage
     * @dev Updates the refereeData and referrerOf mapping and allReferees list in the storage
     * @param _referee Data related to the referee
     * @param _referrer The address of the referrer
     */
    function _updateRefereeStorage(
		RefereeInfo memory _referee,
		address _referrer
	) internal {
		RefereeStorage storage _refereeStorage = LibRefereeStorage
			.diamondStorage();
		// add new referee to referee data mapping
		_refereeStorage.refereeData[_referee.id][
			_referee.campaignId
		] = _referee;
		// if referrer is not zero address, add as the referrer
		if (_referrer != address(0))
			_refereeStorage.referrerOf[_referee.id][
				_referee.campaignId
			] = _referrer;
		// update allReferees list
		AppStorage storage _appStorage = LibAppStorage.diamondStorage();
		bool _isReferee = _appStorage.isReferee[_referee.id];
		if (!_isReferee) {
			_appStorage.isReferee[_referee.id] = true;
		}
	}
}
