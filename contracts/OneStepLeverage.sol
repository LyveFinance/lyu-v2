// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "./Addresses.sol";
import  "./Interfaces/IAMM.sol";
import  "./Interfaces/IBorrowerOperations.sol";
import  "./Interfaces/IVesselManager.sol";
import  "./Interfaces/IAdminContract.sol";
import "./DebtFlashMint.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/IPriceFeed.sol";


contract OneStepLeverage is IERC3156FlashBorrower,Addresses ,ReentrancyGuard{
    using SafeERC20 for IERC20;

    address public immutable  debtFlashMint;
    mapping(address => bool) public isAssetInWhitelist;

    uint256 public constant  MAX_LEFTOVER_R = 1e18;

	mapping(address => IAMM) public amm;

    event AMMSet(address indexed asset, address indexed ammAddress);

    event AssetAddedToWhitelist(address indexed asset);


    event LeverageOpened(address indexed borrower, address indexed asset, uint256 assetAmount, uint256 loanAmount);

    event LeverageAdjusted(address indexed borrower, address indexed asset, uint256 assetChangeAmount, uint256 debateAmount);


    error AmmCannotBeZero();

    error CollateralTokenCannotBeZero();

    error DebtFlashMintCannotBeZero();

    error NotDebtFlashMint();

    error InvalidInitiator();

    constructor(address _debtFlashMint){
        if (address(_debtFlashMint) == address(0)) {
            revert DebtFlashMintCannotBeZero();
        }
        debtFlashMint = _debtFlashMint;
        IERC20(debtToken).approve(_debtFlashMint, type(uint256).max);
        __Ownable_init();
    }

     modifier onlyWhitelistedAsset(address _asset) {
        require(isAssetInWhitelist[_asset], "Asset is not whitelisted");
        _;
    }

    function setAMM(address _asset, IAMM _ammAddress) public onlyOwner {
        require(_asset != address(0), "asset address cannot be zero");
        require(address(_ammAddress) != address(0), "_amm address cannot be zero");
        amm[_asset] = _ammAddress;
        emit AMMSet(_asset, address(_ammAddress)); 

    }
    function addToWhitelist(address _asset) external onlyOwner {
        require(_asset != address(0), "Asset address cannot be zero");
        isAssetInWhitelist[_asset] = true;
        IERC20(_asset).approve(address(borrowerOperations), type(uint256).max);
        emit AssetAddedToWhitelist(_asset);
    }
    function approve (address erc20 ) external onlyOwner {
		IERC20(erc20).approve(debtFlashMint,type(uint256).max);
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
            0,
            ammData
        );
        DebtFlashMint(debtFlashMint).flashLoan(this, debtToken, _loanAmount, data);
        emit LeverageOpened(msg.sender, _asset, _assetAmount, _loanAmount); 

    }

    function adjustLeverage(
        address _asset,
		uint256 _assetAmount,
        uint256 _loanAmount,
        uint256 _minAssetAmount,
		address _upperHint,
		address _lowerHint,
        bytes calldata ammData
    ) external{
        _adjustLeverageCheckParam(_asset, msg.sender, _assetAmount, _loanAmount);
        IERC20(_asset).transferFrom(msg.sender, address(this), _assetAmount);
        bytes memory data = abi.encode(
            msg.sender,
            _asset,
            _assetAmount,
            _loanAmount,
            _minAssetAmount,
            _upperHint,
            _lowerHint,
            1,
            ammData
        );
        DebtFlashMint(debtFlashMint).flashLoan(this, debtToken, _loanAmount, data);
        emit LeverageAdjusted(msg.sender, _asset, _assetAmount, _loanAmount); 

    }

    function _checkParam (
        address _asset,
		uint256 _assetAmount,
        uint256 _loanAmount
    ) internal view {
        uint256 _assetPrice = IPriceFeed(priceFeed).fetchPrice(_asset);
        uint256 maxLoanAmount = getMaxBorrowAmount(_asset, _assetPrice, _assetAmount); 
        require(maxLoanAmount >= _loanAmount,"exceeded maximum borrowing");
        require(address(amm[_asset]) != address(0),"amm is null");
    }

    // Calculate the maximum number of LYUs that can be borrowed based on the given collateral
    function getMaxBorrowAmount(address _asset, uint256 _assetPrice, uint256 _assetAmount) public view returns (uint256) {
        uint256 maxLeverage = getMaxLeverage(_asset);

        // To calculate the amount of LYU that can be borrowed, the formula is (x - 1) * p, where x is the leverage multiple and p is the asset price
        uint256 maxBorrowAmount = (_assetAmount * _assetPrice / MAX_LEFTOVER_R) * (maxLeverage - 1e18) / MAX_LEFTOVER_R;
        return maxBorrowAmount;
    }

    // calculate the maximum leverage multiplier for opening leverage
    function getMaxLeverage (address _asset) public view returns (uint256){
        uint256 mcr = IAdminContract(adminContract).getMcr(_asset);
        // To calculate the maximum leverage ratio, mcr needs to be based on 1e18 as the base unit
        // The total assets are mcr and the mortgage capital is mcr - 1e18
        return  mcr * MAX_LEFTOVER_R /(mcr - 1 ether);
    }

    function onFlashLoan(
        address initiator,
        address ,
        uint256 loanAmount,
        uint256 fee,
        bytes calldata data
    ) external nonReentrant
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
            uint256 _isAdjustType,
            bytes memory _ammData
        ) = abi.decode(data, (address,address, uint256, uint256,uint256, address, address, uint256,bytes));

        IERC20(debtToken).safeApprove(address(amm[_asset]),loanAmount);
        uint256 leveragedCollateralChange = amm[_asset].swap(debtToken,_asset,_ammData);

        require(leveragedCollateralChange >= _minAssetAmount,"min exchange error");
        uint256 debateAmount = loanAmount+ fee;
        uint256 assetAmount = _assetAmount+ leveragedCollateralChange;

        if (_isAdjustType == 0) {
            _openVessel(_borrower, _asset, _assetAmount, debateAmount, _upperHint, _lowerHint);
        } else if (_isAdjustType == 1) {
            _adjustVessel(_borrower, _asset, assetAmount, debateAmount, _upperHint, _lowerHint);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _openVessel(
        address _borrower, 
        address _asset,
        uint256 _assetAmount,
        uint256 _debateAmount,
        address _upperHint, address _lowerHint) internal  {
            IBorrowerOperations(borrowerOperations).openVessel(_borrower, _asset, _assetAmount, _debateAmount, _upperHint, _lowerHint);
    }

    function _adjustVessel(
        address _borrower,
        address _asset,
        uint256 _assetChangeAmount, 
        uint256 _debateAmount,
        address _upperHint,
        address _lowerHint) internal {
            bool isDebtIncrease = _debateAmount > 0;
            IBorrowerOperations(borrowerOperations).adjustVessel(_borrower, _asset, _assetChangeAmount , 0, _debateAmount, isDebtIncrease,_upperHint, _lowerHint);
    }

    // calculate the maximum leverage multiple for adjusting leverage
    function getAdjustMaxLeverage (address _asset, address _borrower, uint256 _assetPrice, uint256 _assetAmount) public view returns (uint256) {
        uint256 _coll = IVesselManager(vesselManager).getVesselColl(_asset, _borrower);
		uint256 _debt = IVesselManager(vesselManager).getVesselDebt(_asset, _borrower);
        uint256 ownColl = _assetAmount + _coll;
        uint256 canMaxBorrowAmount = getAdjustLeverageCanMaxBorrowAmount(_asset, _coll, _debt, _assetPrice, _assetAmount);
        return  (ownColl + canMaxBorrowAmount) * MAX_LEFTOVER_R / ownColl;
    }

    // calculate the borrowable amount to adjust leverage
    function getAdjustLeverageCanMaxBorrowAmount(
        address _asset,
        uint256 _coll, 
        uint256 _debt,
        uint256 _assetPrice, 
        uint256 _assetAmount) public view returns (uint256) {
            uint256 ownColl = _assetAmount + _coll;
            uint256 mcr = IAdminContract(adminContract).getMcr(_asset);
            uint256 newMaxBorrowAmount = ownColl * _assetPrice / mcr;
            uint256 canMaxBorrowAmount = newMaxBorrowAmount - _debt;
            return canMaxBorrowAmount;
    }

    function _adjustLeverageCheckParam (
        address _asset,
        address _borrower,
		uint256 _assetAmount,
        uint256 _loanAmount
    ) internal view {
        uint256 _assetPrice = IPriceFeed(priceFeed).fetchPrice(_asset);
        uint256 coll = IVesselManager(vesselManager).getVesselColl(_asset, _borrower);
		uint256 debt = IVesselManager(vesselManager).getVesselDebt(_asset, _borrower);
        uint256 maxLoanAmount = getAdjustLeverageCanMaxBorrowAmount(_asset, coll, debt, _assetPrice, _assetAmount); 
        require(maxLoanAmount >= _loanAmount,"exceeded maximum borrowing");
        require(address(amm[_asset]) != address(0),"amm is null");
    }
}
