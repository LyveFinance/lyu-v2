// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title Lyve
/// @author lyve.finance
/// @notice The native token in the Lyve V2 ecosystem
/// @dev Emitted by the Minter and in conversions from v1 LYVE
contract Token is IERC20, ERC20Permit {
    address public minter;

    error NotMinter();
    error NotOwner(); 
    
    constructor(string memory name,string memory symbol) ERC20(name,symbol) ERC20Permit(symbol) {
        minter = msg.sender;
    }
  

    /// @dev No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        if (msg.sender != minter) revert NotMinter();
        minter = _minter;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        if (msg.sender != minter ) revert NotMinter();
        _mint(account, amount);
        return true;
    }
    /**
   * @dev Called by the bridge to burn tokens during a bridge transaction.
   * @dev User should first have allowed the bridge to spend tokens on their behalf.
   * @param _account The account from which tokens will be burned.
   * @param _amount The amount of tokens to burn.
   */
  function burn(address _account, uint256 _amount) external  {
    if (_account != msg.sender) _spendAllowance(_account, msg.sender, _amount);
    _burn(_account, _amount);
  }
}
