// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Addresses.sol";
import  "./Interfaces/IAMM.sol";
import  "./Interfaces/IBorrowerOperations.sol";
import "./DebtFlashMint.sol";
import "./Interfaces/IDebtToken.sol";





contract OneStepLeverage is IERC3156FlashBorrower,Addresses {
    using SafeERC20 for IERC20;

    IAMM public immutable  amm;
    IERC20 public immutable  collateralToken;
    address public immutable  debtFlashMint;
    
    uint256 public constant  MAX_LEFTOVER_R = 1e18;

    error AmmCannotBeZero();

    error CollateralTokenCannotBeZero();

    error DebtFlashMintCannotBeZero();

    error NotDebtFlashMint();

    error InvalidInitiator();

    error ZeroDebtChange();

    event LeveragedPositionAdjusted(
        address indexed position,
        uint256 principalCollateralChange,
        bool principalCollateralIncrease,
        uint256 debtChange,
        bool isDebtIncrease,
        uint256 leveragedCollateralChange
    );

    constructor(
        IAMM amm_,
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
		address _upperHint,
		address _lowerHint,
        address _minReturn, 
        bytes calldata ammData
    ) external{
        bytes memory data = abi.encode(

            msg.sender,
            _asset,
            _assetAmount,
            _debateAmount,
            _upperHint,
            _lowerHint,
            _minReturn,
            ammData
        );
        DebtFlashMint(debtFlashMint).flashLoan(this, debtToken, _debateAmount, data);
    }


    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
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

        (   ,
            address _asset,
            uint256 _assetAmount,
            ,
            address _upperHint,
            address _lowerHint,
            uint256 _minReturn,
            bytes memory _ammData
        ) = abi.decode(data, (address, address, uint256, uint256, address, address,uint256, bytes));

        uint256 leveragedCollateralChange = amm.swap(IERC20(debtToken), IERC20(_asset), amount, _minReturn, _ammData);
        _delegateOpenVessel( borrowerOperations,_asset, _assetAmount + leveragedCollateralChange, amount, _upperHint, _lowerHint);
        IDebtToken(debtToken).transferFrom(msg.sender, address(this), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _delegateOpenVessel(
        address _borrowerOperations,
        address _asset,
        uint256 _assetAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) internal {
    bytes memory data = abi.encodeWithSelector(
        IBorrowerOperations.openVessel.selector,
        _asset,
        _assetAmount,
        _debtAmount,
        _upperHint,
        _lowerHint
    );
    (bool success, ) = _borrowerOperations.delegatecall(data);
    require(success, "delegatecall failed");
}

}
