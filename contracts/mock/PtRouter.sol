
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/ICurveRouter.sol";
import "../Interfaces/IAMM.sol";
 import "../Interfaces/IPtRouter.sol";

contract PtRouter is IAMM,Ownable {

  IERC20 public immutable  WETH;
  IERC20 public immutable  lyu;
  IPtRouter public immutable amm;
  address public oneStepLeverage;

  constructor( IERC20 _WETH,IERC20 _lyu,address _amm,address _oneStepLeverage){
       WETH = _WETH;
       lyu = _lyu;
       amm = IPtRouter(_amm) ;
       oneStepLeverage = _oneStepLeverage;
    }
    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm){
      IERC20(lyu).transferFrom(msg.sender,address(this),input.netTokenIn);
      IERC20(WETH).transfer(msg.sender,minPtOut);
      netPtOut = minPtOut;
    }

    function swap( bytes calldata _ammData) external  returns (uint256 amountOut) {
      require(msg.sender == oneStepLeverage,"not oneStepLeverage");
      (address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams memory guessPtOut,
        TokenInput memory input,
        LimitOrderData memory limit) = abi.decode(_ammData,(address , address ,uint256 ,ApproxParams  ,TokenInput  ,LimitOrderData  ));
        IERC20(input.tokenIn).approve(address(amm),input.netTokenIn);
       (uint256 netPtOut,  ,  ) = amm.swapExactTokenForPt(msg.sender, market, minPtOut, guessPtOut, input,limit);
        return netPtOut;
    }

      
        
}