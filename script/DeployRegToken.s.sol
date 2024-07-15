// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RegToken.sol";

contract DeployRegToken is Script {
    function run() external {
        address payable priceFeed = payable(
            0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41
        );
        address owner = msg.sender;
        uint256 _feeRate = 5;

        vm.startBroadcast();

        // Deploy the RegToken contract
        RegToken regToken = new RegToken(owner, _feeRate, priceFeed);

        console.log("RegToken deployed at:", address(regToken));

        vm.stopBroadcast();
    }
}
