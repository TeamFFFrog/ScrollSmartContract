// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FishToken is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("Fish Token", "FISH") Ownable(initialOwner) {}

    // Mint new Fish tokens
    function mintOrReward(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Burn Fish tokens
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
