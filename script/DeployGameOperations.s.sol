// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameOperations.sol";

contract DeployGameOperations is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        address payable regTokenAddress = payable(
            0x0769a90bea3121599DA6b48eD5fBdE47ABd83EBE
        );
        address fishTokenAddress = 0xf94aa9537CfA0E4d21F8e41457326A57fb1368aC;

        // Deploy the GameOperations contract
        GameOperations gameOperations = new GameOperations(
            regTokenAddress,
            fishTokenAddress,
            msg.sender
        );

        // Transfer ownership of tokens to the GameOperations contract
        RegToken regToken = RegToken(regTokenAddress);
        FishToken fishToken = FishToken(fishTokenAddress);
        regToken.transferOwnership(address(gameOperations));
        fishToken.transferOwnership(address(gameOperations));

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Output the addresses for verification
        console.log("GameOperations deployed at:", address(gameOperations));
    }
}
