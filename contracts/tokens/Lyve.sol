// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/v2/OFTV3.sol";

/// @title LYVE Debt Token
/// @notice This contract locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.
contract Lyve is OFTV3 {
    constructor(address _layerZeroEndpoint) OFTV3("LYVE Token", "LYVE", _layerZeroEndpoint) {}
}
