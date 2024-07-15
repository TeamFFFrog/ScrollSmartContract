// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FishToken.sol";

contract DeployFishToken is Script {
    function run() external {
        address initialOwner = msg.sender;

        vm.startBroadcast();
        FishToken fishToken = new FishToken(initialOwner);
        vm.stopBroadcast();

        console.log("FishToken deployed to:", address(fishToken));
    }
}
