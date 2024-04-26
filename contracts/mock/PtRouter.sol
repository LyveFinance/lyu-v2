
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/ICurveRouter.sol";
import "../Interfaces/IAMM.sol";
 
contract PtRouter is IAMM,Ownable {

  IERC20 public immutable  WETH;
  IERC20 public immutable  lyu;
  ICurveRouter public immutable amm;

  constructor( IERC20 _WETH,IERC20 _lyu,address _amm){
       WETH = _WETH;
       lyu = _lyu;
       amm = ICurveRouter(_amm) ;
    }
    function exchange(address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools) internal returns (uint256 ){
       IERC20(lyu).transferFrom(msg.sender,address(this),_amount);
       IERC20(WETH).transfer(msg.sender,_expected);
       return _expected;
    }

    function swap( bytes calldata _ammData) external  returns (uint256 amountOut){

      (address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools) = abi.decode(_ammData,(address[11], uint256[5][5] ,uint256 ,uint256 ,address[5] ));
       
      uint256 leveragedCollateralChange = amm.exchange(_router, _swap_params, _amount, _expected, _pools);

      return leveragedCollateralChange;
    }
        
}