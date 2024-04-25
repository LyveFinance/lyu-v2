
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../Interfaces/oracles/IPPtOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PtOracle  is IPPtOracle,Ownable{

    uint256 public rate = 941386389210286442;

    bool public increaseCardinalityRequired = false;
    bool public oldestObservationSatisfied = true;

    function getPtToAssetRate(address market, uint32 duration) external view returns (uint256 ptToAssetRate){
        return rate;
    }

    function getOracleState(
        address market,
        uint32 duration
    ) external view returns (bool , uint16 , bool ){
      return (increaseCardinalityRequired,0,oldestObservationSatisfied);
    }

   function setParam(uint256 _rate, bool _increaseCardinalityRequired,bool _oldestObservationSatisfied)
     external  onlyOwner {
        rate = _rate;
        increaseCardinalityRequired = _increaseCardinalityRequired;
        oldestObservationSatisfied = _oldestObservationSatisfied;
   }
        
}