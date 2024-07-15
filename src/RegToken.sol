// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RegToken is ERC20, Ownable {
    AggregatorV3Interface public priceFeed;
    uint256 public feeRate; // Fee rate in basis points (e.g., 1 = 1%)

    event FeeRateChanged(uint256 newFeeRate);

    constructor(
        address initialOwner,
        uint256 _feeRate,
        address _priceFeed
    ) ERC20("Reg Token", "REG") Ownable(initialOwner) {
        feeRate = _feeRate;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Get the latest price of ETH/USD
    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int256 price /*uint256 startedAt*/ /*uint256 timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // price is in 8 decimals, convert to 18 decimals
    }

    // Calculate the amount of REG tokens for given ETH amount
    function calculateRegAmount(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        return (ethAmount * ethPrice) / 1e18;
    }

    // Buy Reg tokens with ETH, deducting fee
    function buyRegTokens() public payable {
        require(msg.value > 0, "Must send ETH to buy REG tokens");
        uint256 fee = (msg.value * feeRate) / 100;
        uint256 netEthAmount = msg.value - fee;
        uint256 regAmount = calculateRegAmount(netEthAmount);
        _mint(msg.sender, regAmount);
    }

    // Sell Reg tokens for ETH, deducting fee
    function sellRegTokens(uint256 regAmount) public {
        require(balanceOf(msg.sender) >= regAmount, "Insufficient REG balance");
        uint256 ethAmount = calculateEthAmount(regAmount);
        uint256 fee = (ethAmount * feeRate) / 100;
        uint256 netEthAmount = ethAmount - fee;
        require(
            address(this).balance >= netEthAmount,
            "Insufficient ETH balance in contract"
        );
        _burn(msg.sender, regAmount);
        payable(msg.sender).transfer(netEthAmount);
    }

    // Calculate the amount of ETH for given REG tokens
    function calculateEthAmount(
        uint256 regAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        return (regAmount * 1e18) / ethPrice;
    }

    // Withdraw ETH from the contract (only owner)
    function withdrawETH(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        payable(owner()).transfer(amount);
    }

    // Update fee rate (only owner)
    function updateFeeRate(uint256 newFeeRate) public onlyOwner {
        require(newFeeRate <= 100, "Fee rate too high"); // Ensure fee rate is not more than 100%
        feeRate = newFeeRate;
        emit FeeRateChanged(newFeeRate);
    }

    // Allow the owner to burn tokens from any address
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    // Receive ETH to the contract
    receive() external payable {}
}
