// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract GasPool is Ownable {
	// do nothing, as the core contracts have permission to send to and burn from this address

	string public constant NAME = "GasPool";

	address public borrowerOperations;
	address public vesselManager;

	function initialize(address _borrowerOperations,address _vesselManager) external onlyOwner {
		borrowerOperations = _borrowerOperations;
		vesselManager = _vesselManager;
	}

	function approve (address erc20 ) external onlyOwner {
		IERC20(erc20).approve(borrowerOperations,type(uint256).max);
		IERC20(erc20).approve(vesselManager,type(uint256).max);
	}
}
