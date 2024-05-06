// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./storage/LibAffiliateStorage.sol";
import "./storage/LibCampaignStorage.sol";
import "./storage/LibRefereeStorage.sol";
import "./storage/LibAppStorage.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";

library Utilities {

  	function _getMembershipLock() internal view returns (address) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.membershipLock;
	}

    function _getMultiLevelReferrers(address _levelOneReferrerAddress, address _campaignId) view internal returns(address, address) {
		RefereeStorage storage refereeStorage = LibRefereeStorage.diamondStorage();
		address levelTwoReferrer = refereeStorage.referrerOf[_levelOneReferrerAddress][_campaignId];
		address levelThreeReferrer = refereeStorage.referrerOf[levelTwoReferrer][_campaignId];
		return (levelTwoReferrer, levelThreeReferrer);
	}

	function _isLockManager(
		address _lockAddress
	) internal view returns (bool isManager) {
		isManager = IPublicLockV12(_lockAddress).isLockManager(msg.sender);
	}

    function _isMember(address _user) 
		internal 
		view returns (bool _hasValidMembership) 
	{
		address membershipLock = _getMembershipLock();
		if (membershipLock == address(0)) return false;
		_hasValidMembership = IPublicLockV12(membershipLock).getHasValidKey(_user);
	}

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
		// if referrer not zero address add as the referrer
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
