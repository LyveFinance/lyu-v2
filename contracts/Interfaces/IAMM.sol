// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAMM {
  
    function swap(
        bytes calldata extraData
    )
        external
        returns (uint256 amountOut);
}
