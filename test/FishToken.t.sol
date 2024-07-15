// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FishToken.sol";

contract FishTokenTest is Test {
    FishToken public fishToken;
    address owner = address(0xABCD);
    address user1 = address(0x1234);
    address user2 = address(0x5678);

    function setUp() public {
        // Deploy FishToken contract
        vm.prank(owner);
        fishToken = new FishToken(owner);
    }

    function testInitialSupply() public view {
        uint256 ownerBalance = fishToken.balanceOf(owner);
        assertEq(ownerBalance, 0, "Initial Supply should be 0.");
    }

    function testMint() public {
        vm.prank(owner);
        fishToken.mintOrReward(user1, 100 * 10 ** 18);

        uint256 user1Balance = fishToken.balanceOf(user1);
        assertEq(user1Balance, 100 * 10 ** 18, "User1 should have 100 FISH");
    }

    function testBurn() public {
        vm.prank(owner);
        fishToken.mintOrReward(user1, 100 * 10 ** 18);

        vm.prank(user1);
        fishToken.burn(50 * 10 ** 18);

        uint256 user1Balance = fishToken.balanceOf(user1);
        assertEq(
            user1Balance,
            50 * 10 ** 18,
            "User1 should have 50 FISH after burning 50"
        );

        uint256 totalSupply = fishToken.totalSupply();
        assertEq(
            totalSupply,
            50 * 10 ** 18,
            "Total supply should be reduced by 50 FISH"
        );
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user1
            )
        );
        fishToken.mintOrReward(user2, 100 * 10 ** 18);
    }

    function testOnlyOwnerCanReward() public {
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user1
            )
        );
        fishToken.mintOrReward(user2, 100 * 10 ** 18);
    }
}
