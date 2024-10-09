// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {QVoting} from "../src/QVoting.sol"; // Import the QVoting contract

contract QVotingScript is Script {
    QVoting public votingContract; // Declare the QVoting contract instance

    // Optional setup function; can be used for initial configurations
    function setUp() public {}

    // Main function that executes the script to deploy the voting contract
    function run() public {
        vm.startBroadcast(); // Start broadcasting transactions

        // Deploy a new instance of the QVoting contract
        votingContract = new QVoting(
            msg.sender, // Creator address (you can change this as needed)
            msg.sender, // Blocker address (you can change this as needed)
            msg.sender // Register address (you can change this as needed)
        );

        console.log("QVoting contract deployed at:", address(votingContract)); // Log the contract address

        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
