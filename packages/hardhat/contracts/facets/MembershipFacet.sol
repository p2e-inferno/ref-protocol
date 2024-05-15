// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/Utilities.sol";
import { Modifiers } from "../libraries/Modifiers.sol";

// @title UNADUS: MembershipFacet
/// @author Danny Thomx
/// @notice Manages memberships

contract MembershipFacet is Modifiers {

    function getMembershipLock() public view returns (address membershipLock) {
		membershipLock = Utilities._getMembershipLock();
	}

	function setMembershipLock(
		address _membershipLock
	) public onlyOwner {
		AppStorage storage s = LibAppStorage.diamondStorage();
		s.membershipLock = _membershipLock;
	}

}
