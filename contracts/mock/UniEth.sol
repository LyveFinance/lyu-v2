// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILyve} from "../Interfaces/ILyve.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Lyve
/// @author lyve.finance
/// @notice The native token in the Lyve V2 ecosystem
/// @dev Emitted by the Minter and in conversions from v1 LYVE
contract UniEth is ILyve, ERC20Permit {
    address public minter;

    constructor() ERC20("uniETH", "uniETH") ERC20Permit("uniETH") {
        minter = msg.sender;
    }
  

    /// @dev No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        if (msg.sender != minter) revert NotMinter();
        minter = _minter;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        if (msg.sender != minter ) revert NotMinter();
        require(totalSupply() + amount <= 10_000_000 ether, "more than max totalSupply");
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
