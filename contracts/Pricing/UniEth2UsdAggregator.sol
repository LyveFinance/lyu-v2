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

contract UniEth2UsdAggregator  is AggregatorV3Interface{


    uint256 internal constant PRECISION = 1 ether;

	AggregatorV3Interface public immutable WETH2USDAggregator;

   // Updating the proxy address is a security-critical action which is why
   // we have made it immutable.
   IRockXStaking public immutable api3Proxy;

   constructor(address _api3Proxy,address _WWETH2USDAggregator) {
       api3Proxy = IRockXStaking(_api3Proxy);
	   WETH2USDAggregator = AggregatorV3Interface(_WWETH2USDAggregator);
   }

  function decimals() external view override returns (uint8) {
		return WETH2USDAggregator.decimals();
	}

	function description() external pure override returns (string memory) {
		return "UinEth2UsdPriceAggregator";
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
		( roundId,  answer, startedAt , updatedAt, answeredInRound) = WETH2USDAggregator.getRoundData(_roundId);
         (uint256 uniETHAnswer,uint256 uniETHUpdatedAt ) = _WETH2UniETH(uint256(answer));
		 require(uniETHUpdatedAt > 0, "uniETH upAt cannot be zero");
		 require(updatedAt > 0, "ETH upAT cannot be zero");
		 answer = int256(uniETHAnswer);
		 updatedAt = uniETHUpdatedAt > updatedAt ? updatedAt : uniETHUpdatedAt;
	
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
		( roundId,  answer, startedAt , updatedAt, answeredInRound) = WETH2USDAggregator.latestRoundData();
         (uint256 uniETHAnswer,uint256 uniETHUpdatedAt ) = _WETH2UniETH(uint256(answer));
		 require(uniETHUpdatedAt > 0, "uniETH upAt cannot be zero");
		 require(updatedAt > 0, "ETH upAT cannot be zero");
		 answer = int256(uniETHAnswer);
		 updatedAt = uniETHUpdatedAt > updatedAt ? updatedAt : uniETHUpdatedAt;
	}

	function version() external pure override returns (uint256) {
		return 1;
	}

	// Internal/Helper functions ----------------------------------------------------------------------------------------

	function _WETH2UniETH(uint256 WETHPrice) internal view returns (uint256 ,uint256 ) {
		require(WETHPrice > 0, "WETHPrice value cannot be zero");
		uint256 rate = api3Proxy.exchangeRatio();
		uint256 updatedAt = block.timestamp;
		require(rate > 0, "uniETH rate cannot be zero");
		uint256 price = WETHPrice* rate/ PRECISION;
		return (price,updatedAt);
	}
}