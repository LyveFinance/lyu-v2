// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./fee/BaseOFTWithFee.sol";

contract OFTV3 is BaseOFTWithFee, ERC20 {

    event WhitelistChanged(address _whitelisted, bool whitelisted);


    mapping(address => bool) public emergencyStopMintingCollateral;

    uint internal immutable ld2sdRate;

    mapping(address => bool) public whitelistedContracts;


    constructor(string memory _name, string memory _symbol, address _lzEndpoint) ERC20(_name, _symbol) BaseOFTWithFee(_lzEndpoint) {
        uint8 decimals = decimals();
        ld2sdRate = 10 ** (decimals - sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/


    function _requireCallerIsWhitelistedContract() internal view {
        require(whitelistedContracts[msg.sender], "Caller is not a whitelisted SC");
    }
    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function mint( address _account, uint256 _amount) external {
        _requireCallerIsWhitelistedContract();
        require(totalSupply() + _amount <= 10_000_000 ether, "more than max totalSupply");
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        address spender = _msgSender();
        if (_account != spender) _spendAllowance(_account, spender, _amount);
        _burn(_account, _amount);
    }


    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        _requireValidRecipient(_toAddress);
        require(totalSupply() + _amount <= 10_000_000 ether, "more than max totalSupply");
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        _requireValidRecipient(_to);
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _requireValidRecipient(address _recipient) internal view {
        require(_recipient != address(0) && _recipient != address(this), " Cannot transfer tokens directly to the token contract or the zero address");
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
    function addWhitelist(address _address) external onlyOwner {
        whitelistedContracts[_address] = true;
        emit WhitelistChanged(_address, true);
    }

    function removeWhitelist(address _address) external onlyOwner {
        whitelistedContracts[_address] = false;
        emit WhitelistChanged(_address, false);
    }

}
