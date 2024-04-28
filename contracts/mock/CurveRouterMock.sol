
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/ICurveRouter.sol";
 
contract CurveRouterMock is ICurveRouter,Ownable {

  IERC20 public immutable  tokenIn;
  IERC20 public immutable  tokneOut;
  address public oneStepLeverage;


  constructor( IERC20 _tokenIn,IERC20 _tokneOut){
       tokenIn = _tokenIn;
       tokneOut = _tokneOut;
    }
    function exchange(address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools) external returns (uint256 ){
       IERC20(tokenIn).transferFrom(msg.sender,address(this),_amount);
       IERC20(tokneOut).transfer(msg.sender,_expected);
       return _expected;
    }
        
}