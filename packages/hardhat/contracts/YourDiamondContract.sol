// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com>, Twitter/Github: @mudgen
* EIP-2535 Diamonds
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import "./libraries/storage/LibAppStorage.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

// This is used in diamond constructor
// more arguments are added to this struct
// this avoids stack too deep errors
struct DiamondArgs {
	address owner;
	address init;
	bytes initCalldata;
}

contract YourDiamondContract {
	// Event for random Ether received
    event YoloEtherReceived(address indexed sender, uint256 amount);
    // Event for random Ether withdrawal
    event YoloEtherWithdrawn(address indexed to, uint256 amount);
	// Variable to track random Ether received
	uint256 yoloEthBalance = 0;
	constructor(
		IDiamondCut.FacetCut[] memory _diamondCut,
		DiamondArgs memory _args
	) payable {
		LibDiamond.setContractOwner(_args.owner);
		LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

		// Code can be added here to perform actions and set state variables.
	}

	// Find facet for function that is called and execute the
	// function if a facet is found and return any value.
	fallback() external payable {
		LibDiamond.DiamondStorage storage ds;
		bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
		// get diamond storage
		assembly {
			ds.slot := position
		}
		// get facet from function selector
		address facet = ds
			.facetAddressAndSelectorPosition[msg.sig]
			.facetAddress;
		if (facet == address(0)) {
			revert FunctionNotFound(msg.sig);
		}
		// Execute external function from facet using delegatecall and return any value.
		assembly {
			// copy function selector and any arguments
			calldatacopy(0, 0, calldatasize())
			// execute function call using the facet
			let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
			// get any return value
			returndatacopy(0, 0, returndatasize())
			// return any return value or error back to the caller
			switch result
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}

	receive() external payable {
		if(msg.value > 0) {
			// Track the random Ether
			uint256 amount = msg.value;
			yoloEthBalance += amount;
			emit YoloEtherReceived(msg.sender, amount);
		}
	}

	function initializeUnadus() external {
		require(IERC173(address(this)).owner() == msg.sender, "Not Owner");
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		appStorage.unadusAddress = address(this);
	}

	function getUnadusAddress() external view returns(address unadus) {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		unadus = appStorage.unadusAddress;
	}

  	/**
     * @notice Withdraw random Ether sent to the contract
     * @dev Withdraws all the random Ether without affecting the deposited Ether.
     * @param _to The address to which the Ether should be sent.
     */
	function withdrawYoloEth(address payable _to) external {
		require(IERC173(address(this)).owner() == msg.sender, "Not Owner");
        require(yoloEthBalance > 0, "No yolo ETH available");

        uint256 amount = yoloEthBalance;
        yoloEthBalance = 0;

        (bool success, ) = _to.call{value: amount}("");
        require(success, "Transfer failed");

        emit YoloEtherWithdrawn(_to, amount);
    }

}
