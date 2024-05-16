// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/Utilities.sol";
import { Modifiers } from "../libraries/Modifiers.sol";

// @title UNADUS: MembershipFacet
/// @author Danny Thomx
/// @notice Manages memberships
contract MembershipFacet is Modifiers {
	
	/**
     * @notice Get the address of the membership lock
     * @return membershipLock The address of the membership lock
     */
    function getMembershipLock() public view returns (address membershipLock) {
		membershipLock = Utilities._getMembershipLock();
	}
	
	/**
     * @notice Set the address of the membership lock
     * @dev Can only be called by the contract owner
     * @param _membershipLock The address to set as the membership lock
     */
	function setMembershipLock(
		address _membershipLock
	) public onlyOwner {
		AppStorage storage s = LibAppStorage.diamondStorage();
		s.membershipLock = _membershipLock;
	}

}
