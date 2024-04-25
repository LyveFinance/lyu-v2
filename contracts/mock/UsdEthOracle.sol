// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface IRockXStaking {
  /// @notice Retrieve price data
  function exchangeRatio()
    external
    view
    returns (uint256);
}

contract UsdEthOracle  is AggregatorV3Interface{


    int256 public _answer = 351191000000;

    
   constructor() {
       
   }

  function decimals() external view override returns (uint8) {
		return 8;
	}

	function description() external pure override returns (string memory) {
		return "ETH/USD";
	}
	function getRoundData(uint80 _roundId)
		external
		view
		override
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		
	}
	function latestRoundData()
		external
		view
		override
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		updatedAt = block.timestamp;
        answer = _answer;
        roundId = 1;
	}

	function version() external pure override returns (uint256) {
		return 1;
	}
    function setAnswer(int256 __answer) external  returns (uint256) {
		 _answer = __answer;
	}

}