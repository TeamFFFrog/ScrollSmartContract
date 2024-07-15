// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RegToken.sol";
import "./FishToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameOperations is Ownable {
    RegToken public regToken;
    FishToken public fishToken;

    mapping(uint256 => string) public gameResults; // Mapping to store IPFS hash of game results

    event GameStarted(uint256 gameId, address[] players);
    event GameEnded(
        uint256 gameId,
        address[] winners,
        address[] losers,
        string ipfsHash
    );
    event Staked(address indexed user, uint256 amount);
    event RewardDistributed(address indexed player, uint256 reward);

    constructor(
        address _regTokenAddress,
        address _fishTokenAddress,
        address _owner
    ) Ownable(_owner) {
        regToken = RegToken(payable(_regTokenAddress)); // Use payable for explicit type conversion
        fishToken = FishToken(_fishTokenAddress);
        transferOwnership(_owner); // Ensure the owner is set correctly
    }

    // Stake REG tokens from 6 players to start a game
    function startGame(
        uint256 gameId,
        address[] calldata players
    ) external onlyOwner {
        require(players.length == 6, "Must have exactly 6 players");
        for (uint256 i = 0; i < players.length; i++) {
            require(
                regToken.balanceOf(players[i]) >= 1 * 10 ** 18,
                "Insufficient REG balance to stake"
            );
            regToken.transferFrom(players[i], address(this), 1 * 10 ** 18);
            emit Staked(players[i], 1 * 10 ** 18);
        }
        emit GameStarted(gameId, players);
    }

    // End the game, distribute rewards, and store IPFS hash
    function endGame(
        uint256 gameId,
        address[] calldata winners,
        address[] calldata losers,
        string memory ipfsHash
    ) external onlyOwner {
        require(winners.length == 3, "Must have exactly 3 winners");
        require(losers.length == 3, "Must have exactly 3 losers");

        // Distribute rewards and return REG to winners
        uint256[] memory rewards = new uint256[](3);
        rewards[0] = 300;
        rewards[1] = 200;
        rewards[2] = 100;

        for (uint256 i = 0; i < winners.length; i++) {
            regToken.transfer(winners[i], 1 * 10 ** 18);
            fishToken.mintOrReward(winners[i], rewards[i] * 10 ** 18);
            emit RewardDistributed(winners[i], rewards[i] * 10 ** 18);
        }

        // Burn REG tokens from losers
        for (uint256 i = 0; i < losers.length; i++) {
            regToken.burnFrom(address(this), 1 * 10 ** 18);
        }

        // Store game result
        gameResults[gameId] = ipfsHash;
        emit GameEnded(gameId, winners, losers, ipfsHash);
    }

    // Retrieve game result
    function getGameResult(
        uint256 gameId
    ) external view returns (string memory) {
        require(
            bytes(gameResults[gameId]).length > 0,
            "Game result does not exist"
        );
        return gameResults[gameId];
    }
}
