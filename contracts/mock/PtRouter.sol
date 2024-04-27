
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/ICurveRouter.sol";
import "../Interfaces/IAMM.sol";
 import "../Interfaces/IPtRouter.sol";

contract PtRouter is IAMM,Ownable {

  IERC20 public immutable  USDC;
  IERC20 public immutable  lyu;
  IPtRouter public immutable ptAmm;
  ICurveRouter public immutable curveAmm;
  address public oneStepLeverage;

  constructor( IERC20 _USDC,IERC20 _lyu,address _ptAmm,address _curveAmm,address _oneStepLeverage){
       USDC = _USDC;
       lyu = _lyu;
       ptAmm = IPtRouter(_ptAmm) ;
       curveAmm = ICurveRouter(_curveAmm) ;
       oneStepLeverage = _oneStepLeverage;
    }
    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external  returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm){
      IERC20(lyu).transferFrom(msg.sender,address(this),input.netTokenIn);
      IERC20(USDC).transfer(msg.sender,minPtOut);
      netPtOut = minPtOut;
    }

    function swap( bytes calldata _ammData) external  payable returns (uint256 amountOut) {
      require(msg.sender == oneStepLeverage,"not oneStepLeverage");

      (bytes memory cureAmmData,bytes memory ptAmmData) = abi.decode(_ammData,(bytes, bytes));

      (address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools) = abi.decode(cureAmmData,(address[11], uint256[5][5] ,uint256 ,uint256 ,address[5] ));
        
      ( ,address market,uint256 minPtOut,ApproxParams memory guessPtOut,TokenInput memory input, LimitOrderData memory limit) = abi.decode(ptAmmData,(address , address ,uint256 ,ApproxParams  ,TokenInput  ,LimitOrderData  ));

        IERC20(lyu).transferFrom(msg.sender,address(this),_amount);
        IERC20(lyu).approve(address(curveAmm),_amount);       
        uint256 leveragedCollateralChange = curveAmm.exchange(_router, _swap_params, _amount, _expected, _pools);

        require(input.netTokenIn >= leveragedCollateralChange,"pt amm netTokenIn error ");
        IERC20(input.tokenIn).approve(address(ptAmm),input.netTokenIn);
        (uint256 netPtOut,  ,  ) = ptAmm.swapExactTokenForPt(msg.sender, market, minPtOut, guessPtOut, input,limit);
        return netPtOut;
    }
      
        
}