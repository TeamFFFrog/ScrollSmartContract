// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RegToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockPriceFeed is AggregatorV3Interface {
    int256 private price;

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestRoundData()
        public
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
        return (0, price, 0, 0, 0);
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, 0, 0, 0, 0);
    }
}

contract RegTokenTest is Test {
    RegToken public regToken;
    MockPriceFeed public mockPriceFeed;

    address owner = address(0xABCD);
    address user = address(0x1234);

    function setUp() public {
        // Deploy MockPriceFeed and set initial price
        mockPriceFeed = new MockPriceFeed();
        mockPriceFeed.setPrice(2000 * 10 ** 8); // Set price to 3000 USD

        // Deploy RegToken contract
        regToken = new RegToken(owner, 3, address(mockPriceFeed)); // Fee rate is 1%

        // Fund the contract with ETH to support token selling
        vm.deal(address(regToken), 1 ether);

        // Label addresses for better readability
        vm.label(owner, "Owner");
        vm.label(user, "User");
    }

    function test_ReadETHPrice() public view {
        uint256 ethPrice = regToken.getLatestPrice();
        assertEq(ethPrice, 2000 * 10 ** 18); // Convert 8 decimals to 18 decimals
    }

    function testGetLatestPrice() public view {
        uint256 price = regToken.getLatestPrice();
        assertEq(price, 2000 * 10 ** 18, "Price should be 2000 USD");
    }

    function testCalculateRegAmount() public {
        vm.deal(user, 1 ether); // Fund user with 1 ETH
        vm.prank(user);
        uint256 amount = regToken.calculateRegAmount(1e16); // 0.01 ETH
        assertEq(amount, 20 * 1e18, "Wrong amount");
    }

    function testBuyRegTokens() public {
        vm.deal(user, 1 ether); // Fund user with 1 ETH

        vm.prank(user);
        regToken.buyRegTokens{value: 0.1 ether}();
        uint256 regBalance = regToken.balanceOf(user);
        // Deduct 1% fee from 0.1 ether, so net ETH is 0.099 ether
        uint256 expectedRegAmount = regToken.calculateRegAmount(0.097 ether);
        assertEq(
            regBalance,
            expectedRegAmount,
            "User should have correct REG tokens"
        );
    }

    function testSellRegTokens() public {
        vm.deal(user, 1 ether); // Fund user with 1 ETH

        vm.prank(user);
        regToken.buyRegTokens{value: 0.1 ether}();

        uint256 regBalance = regToken.balanceOf(user);
        // Deduct 1% fee from 0.1 ether, so net ETH is 0.099 ether
        uint256 expectedRegAmount = regToken.calculateRegAmount(0.097 ether);
        assertEq(
            regBalance,
            expectedRegAmount,
            "User should have correct REG tokens"
        );

        vm.prank(user);
        regToken.sellRegTokens(expectedRegAmount);

        regBalance = regToken.balanceOf(user);
        assertEq(regBalance, 0, "User should have 0 REG tokens");

        // User should have received ETH minus fee
        uint256 expectedEthAmount = regToken.calculateEthAmount(
            expectedRegAmount
        );
        uint256 fee = (expectedEthAmount * 3) / 100; // 1% fee in basis points
        uint256 netEthAmount = expectedEthAmount - fee;
        uint256 ethBalance = user.balance;
        assertEq(
            ethBalance,
            netEthAmount + 0.9 ether,
            "User should have correct ETH back"
        ); // Initial ETH - 0.1 ETH + netEthAmount
    }

    function testWithdrawETH() public {
        vm.deal(address(regToken), 1 ether); // Fund contract with 1 ETH

        uint256 contractBalance = address(regToken).balance;
        assertEq(contractBalance, 1 ether, "Contract should have 1 ETH");

        vm.prank(owner);
        regToken.withdrawETH(0.5 ether);

        contractBalance = address(regToken).balance;
        assertEq(contractBalance, 0.5 ether, "Contract should have 0.5 ETH");

        uint256 ownerBalance = owner.balance;
        assertEq(ownerBalance, 0.5 ether, "Owner should have 0.5 ETH");
    }

    function testUpdateFeeRate() public {
        uint256 newFeeRate = 2; // 2%
        vm.prank(owner);
        regToken.updateFeeRate(newFeeRate);

        assertEq(
            regToken.feeRate(),
            newFeeRate,
            "Fee rate should be updated to 2%"
        );
    }

    function testOnlyOwnerCanUpdateFeeRate() public {
        uint256 newFeeRate = 200; // 2%
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        regToken.updateFeeRate(newFeeRate);
    }

    function testOnlyOwnerCanWithdrawETH() public {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        regToken.withdrawETH(0.5 ether);
    }
}
