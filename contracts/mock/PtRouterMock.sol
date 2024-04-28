
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

 import "../Interfaces/IPtRouter.sol";

contract PtRouterMock is IPtRouter,Ownable {

  IERC20 public immutable  tokenIn;
  IERC20 public immutable  tokneOut;
  address public oneStepLeverage;

  constructor( IERC20 _tokenIn,IERC20 _tokneOut){
       tokenIn = _tokenIn;
       tokneOut = _tokneOut;
    }
    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external  payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm){
      IERC20(tokenIn).transferFrom(msg.sender,address(this),input.netTokenIn);
      IERC20(tokneOut).transfer(msg.sender,minPtOut);
      netPtOut = minPtOut;
    } 
        
}