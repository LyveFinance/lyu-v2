
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/ICurveRouter.sol";
import "../Interfaces/IAMM.sol";
 import "../Interfaces/IPtRouter.sol";

contract PtRouter is IAMM,Ownable {

  IPtRouter public immutable ptAmm;
  ICurveRouter public immutable curveAmm;
  address public oneStepLeverage;

  constructor( address _ptAmm,address _curveAmm,address _oneStepLeverage){
       ptAmm = IPtRouter(_ptAmm) ;
       curveAmm = ICurveRouter(_curveAmm) ;
       oneStepLeverage = _oneStepLeverage;
    }
  
    function swap( address tokenIn,address tokenOut,bytes calldata _ammData) external  payable returns (uint256 amountOut) {
      require(msg.sender == oneStepLeverage,"not oneStepLeverage");

      (bytes memory cureAmmData,bytes memory ptAmmData) = abi.decode(_ammData,(bytes, bytes));

      (address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools) = abi.decode(cureAmmData,(address[11], uint256[5][5] ,uint256 ,uint256 ,address[5] ));
        
      ( ,address market,uint256 minPtOut,ApproxParams memory guessPtOut,TokenInput memory input, LimitOrderData memory limit) = abi.decode(ptAmmData,(address , address ,uint256 ,ApproxParams  ,TokenInput  ,LimitOrderData  ));

        IERC20(tokenIn).transferFrom(msg.sender,address(this),_amount);
        IERC20(tokenIn).approve(address(curveAmm),_amount);       
        uint256 leveragedCollateralChange = curveAmm.exchange(_router, _swap_params, _amount, _expected, _pools);

        require(input.tokenIn == tokenOut,"TT");
        require(input.netTokenIn >= leveragedCollateralChange,"pt amm netTokenIn error ");
        IERC20(input.tokenIn).approve(address(ptAmm),input.netTokenIn);
        (uint256 netPtOut,  ,  ) = ptAmm.swapExactTokenForPt(msg.sender, market, minPtOut, guessPtOut, input,limit);
        return netPtOut;
    }
      
        
}