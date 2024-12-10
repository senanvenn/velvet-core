// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract MockPriceAggregator {
    uint256 public price;
    uint8 private constant DECIMALS = 8;

    constructor() {
        price = 200000000000;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            0,
            int256(price),
            block.timestamp,
            block.timestamp,
            0
        );
    }

    function setPrice(uint256 price_) external {
        price = price_;
    }
}