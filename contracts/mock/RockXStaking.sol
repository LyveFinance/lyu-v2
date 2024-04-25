
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface IRockXStaking {

  /// @notice Retrieve price data
    function exchangeRatio()
        external
        view
        returns (uint256);
}


contract RockXStaking  is IRockXStaking{

    uint256 public rate = 1056655471347418557;

    function exchangeRatio() external view returns (uint256){

            return rate;
    }

    function setRatio( uint256 _rate) external {
            rate = _rate;
    }

        
}