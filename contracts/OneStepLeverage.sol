// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import "./Addresses.sol";
import  "./Interfaces/IAMM.sol";
import  "./Interfaces/IBorrowerOperations.sol";
import  "./Interfaces/IAdminContract.sol";
import "./DebtFlashMint.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/IPriceFeed.sol";



contract OneStepLeverage is IERC3156FlashBorrower,Addresses {
    using SafeERC20 for IERC20;

    IERC20 public immutable  collateralToken;

    address public immutable  debtFlashMint;
    
    uint256 public constant  MAX_LEFTOVER_R = 1e18;

	mapping(address => IAMM) public amm;

    error AmmCannotBeZero();

    error CollateralTokenCannotBeZero();

    error DebtFlashMintCannotBeZero();

    error NotDebtFlashMint();

    error InvalidInitiator();

    constructor(
        IERC20 _collateralToken,
        address _debtFlashMint
    ){
        if (address(_collateralToken) == address(0)) {
            revert CollateralTokenCannotBeZero();
        }
        if (address(_debtFlashMint) == address(0)) {
            revert DebtFlashMintCannotBeZero();
        }
        collateralToken = _collateralToken;
        debtFlashMint = _debtFlashMint;
        IERC20(debtToken).approve(debtToken, type(uint256).max);
        IERC20(debtToken).approve(_debtFlashMint, type(uint256).max);
        _collateralToken.safeApprove(borrowerOperations, type(uint256).max);
    }

    function openOneStepLeverage(
        address _asset,
		uint256 _assetAmount,
        uint256 _loanAmount,
        uint256 _minAssetAmount,
		address _upperHint,
		address _lowerHint,
        bytes calldata ammData
    ) external{
        _checkParam(_asset,_assetAmount,_loanAmount);
        IERC20(_asset).transferFrom(msg.sender,address(this),_assetAmount);
        bytes memory data = abi.encode(
            msg.sender,
            _asset,
            _assetAmount,
            _loanAmount,
            _minAssetAmount,
            _upperHint,
            _lowerHint,
            ammData
        );
        DebtFlashMint(debtFlashMint).flashLoan(this, debtToken, _loanAmount, data);
    }

    function setAMM(address _asset, IAMM _ammAddress) public onlyOwner {
        require(_asset != address(0), "asset address cannot be zero");
        amm[_asset] = _ammAddress;
    }

    function _checkParam (
        address _asset,
		uint256 _assetAmount,
        uint256 _loanAmount
    ) internal view {
      uint256 maxLoanAmount = getMaxBorrowAmount(_asset, _assetPrice, _assetAmount); 
      require(maxLoanAmount > _loanAmount,"exceeded maximum borrowing");
      require(address(amm[_asset]) != address(0),"amm is null");
      return true;
    }

    // Calculate the maximum number of LYUs that can be borrowed based on the given collateral
    function getMaxBorrowAmount(address _asset, uint256 _assetPrice, uint256 _assetAmount) public view returns (uint256) {
        uint256 maxLeverage = getMaxLeverage(_asset);

        // To calculate the amount of LYU that can be borrowed, the formula is (x - 1) * p, where x is the leverage multiple and p is the asset price
        uint256 maxBorrowAmount = _assetAmount * _assetPrice / MAX_LEFTOVER_R * (maxLeverage - 1e18) / MAX_LEFTOVER_R;
        return maxBorrowAmount;
    }

    function getMaxLeverage (address _asset) public view returns (uint256){
        uint256 mcr = IAdminContract(adminContract).getMcr(_asset);
        return  mcr * MAX_LEFTOVER_R /(mcr - 1 ether);
    }

    function onFlashLoan(
        address initiator,
        address ,
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
                    ,
            uint256 _minAssetAmount,
            address _upperHint,
            address _lowerHint,
            bytes memory _ammData
        ) = abi.decode(data, (address,address, uint256, uint256,uint256, address, address, bytes));

        IERC20(debtToken).transfer(address(amm[_asset]),loanAmount);
        uint256 leveragedCollateralChange = amm[_asset].swap(_ammData);

        require(leveragedCollateralChange >= _minAssetAmount,"min exchange error");
        
        IBorrowerOperations(borrowerOperations).openVessel(_borrower, _asset, _assetAmount + leveragedCollateralChange, loanAmount+ fee, _upperHint, _lowerHint);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }


}
