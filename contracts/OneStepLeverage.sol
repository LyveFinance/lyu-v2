// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import "./Addresses.sol";
import  "./Interfaces/ICurveRouter.sol";
import  "./Interfaces/IBorrowerOperations.sol";
import  "./Interfaces/IAdminContract.sol";
import "./DebtFlashMint.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/IPriceFeed.sol";



contract OneStepLeverage is IERC3156FlashBorrower,Addresses {
    using SafeERC20 for IERC20;

    ICurveRouter public immutable  amm;
    IERC20 public immutable  collateralToken;
    address public immutable  debtFlashMint;
    
    uint256 public constant  MAX_LEFTOVER_R = 1e18;


    error AmmCannotBeZero();

    error CollateralTokenCannotBeZero();

    error DebtFlashMintCannotBeZero();

    error NotDebtFlashMint();

    error InvalidInitiator();

    event LeveragedPositionAdjusted(
        address indexed position,
        uint256 principalCollateralChange,
        bool principalCollateralIncrease,
        uint256 debtChange,
        bool isDebtIncrease,
        uint256 leveragedCollateralChange
    );

    constructor(
        ICurveRouter amm_,
        IERC20 _collateralToken,
        address _debtFlashMint
    ){
        if (address(amm_) == address(0)) {
            revert AmmCannotBeZero();
        }
        if (address(_collateralToken) == address(0)) {
            revert CollateralTokenCannotBeZero();
        }
        if (address(_debtFlashMint) == address(0)) {
            revert DebtFlashMintCannotBeZero();
        }
        amm = amm_;
        collateralToken = _collateralToken;
        debtFlashMint = _debtFlashMint;
        IERC20(debtToken).approve(address(amm), type(uint256).max);
        IERC20(debtToken).approve(debtToken, type(uint256).max);
        IERC20(debtToken).approve(_debtFlashMint, type(uint256).max);
        _collateralToken.safeApprove(borrowerOperations, type(uint256).max);
    }

    function openOneStepLeverage(
        address _asset,
		uint256 _assetAmount,
		uint256 _debateAmount,
        uint256 _loanAmount,
        uint256 _minAssetAmount,
		address _upperHint,
		address _lowerHint,
        bytes calldata ammData
    ) external{
        _checkParam(_asset,_assetAmount,_debateAmount,_loanAmount);
        IERC20(_asset).transferFrom(msg.sender,address(this),_assetAmount);
        bytes memory data = abi.encode(
            msg.sender,
            _asset,
            _assetAmount,
            _debateAmount,
            _loanAmount,
            _minAssetAmount,
            _upperHint,
            _lowerHint,
            ammData
        );
        DebtFlashMint(debtFlashMint).flashLoan(this, debtToken, _loanAmount, data);
    }

    function _checkParam (
        address _asset,
		uint256 _assetAmount,
        uint256 _debateAmount,
		uint256 _loanAmount
    ) internal view {
      require(_debateAmount > _loanAmount,"debate must more than loan");
      uint256 maxLeverage =  getMaxLeverage(_asset);
      uint256 loanAssetAmount =  (maxLeverage - 1 ether)* _assetAmount/MAX_LEFTOVER_R;
      uint256 price = IPriceFeed(priceFeed).fetchPrice(_asset);
      uint256 maxLoanAmount = loanAssetAmount * price/MAX_LEFTOVER_R;
      require(maxLoanAmount > _loanAmount,"Exceeded maximum borrowing");
    }

    function getMaxLeverage (address _asset) public view returns (uint256){
        uint256 mcr = IAdminContract(adminContract).getMcr(_asset);
        return  mcr * MAX_LEFTOVER_R /(mcr-1 ether);
    }



    function onFlashLoan(
        address initiator,
        address,
        uint256 loanAmount,
        uint256 fee,
        bytes calldata data
    ) external
        returns (bytes32)
    {
        if (msg.sender != debtFlashMint) {
            revert NotDebtFlashMint();
        }
        if (initiator != address(this)) {
            revert InvalidInitiator();
        }
        (   address _borrower,
            address _asset,
            uint256 _assetAmount,
            uint256 _debateAmount,
             ,
            uint256 _minAssetAmount,
            address _upperHint,
            address _lowerHint,
            bytes memory _ammData
        ) = abi.decode(data, (address,address, uint256, uint256,uint256,uint256, address, address, bytes));

       (address[11] memory _router, uint256[5][5] memory _swap_params,uint256 _amount,uint256 _expected,address[5] memory _pools)
        = abi.decode(_ammData,(address[11], uint256[5][5] ,uint256 ,uint256 ,address[5] ));

        uint256 leveragedCollateralChange = amm.exchange(_router, _swap_params, _amount, _expected, _pools);(IERC20(debtToken), IERC20(_asset), loanAmount, _ammData);
        require(leveragedCollateralChange > _minAssetAmount,"min error");
        IBorrowerOperations(borrowerOperations).openVessel(_borrower, _asset, _assetAmount + leveragedCollateralChange, _debateAmount, _upperHint, _lowerHint);
        require(_debateAmount > loanAmount + fee,"Need DE > LF");
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }


}
