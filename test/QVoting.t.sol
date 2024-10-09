// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/QVoting.sol";

contract QVotingTest is Test {
    QVoting public qvoting;
    address public admin = address(1);
    address public creator = address(2);
    address public register = address(3);
    address public blocker = address(4);
    address public voter1 = address(5);
    address public voter2 = address(6);

    function setUp() public {
        // Deploy the contract with the admin address
        vm.prank(admin);
        qvoting = new QVoting(creator, blocker, register);
        console2.log("QVoting contract address: ", address(qvoting));
        vm.stopPrank();

        // Register voters
        vm.startPrank(register);
        qvoting.registerAddress(voter1, 1);
        qvoting.registerAddress(voter2, 1);
        vm.stopPrank();
    }

    function testCreateProposal() public {
        vm.startPrank(creator);
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 1 days;
        qvoting.createNewPolicy(1, "proposal1", startTime, endTime);
        QVoting.Proposal memory proposal = qvoting.getProposalDetails(1);
        assertEq(proposal.proposalHash, "proposal1");
        assertEq(proposal.groupID, 1);
        assertEq(proposal.startTime, startTime);
        assertEq(proposal.endTime, endTime);
        vm.stopPrank();
    }

    function testSimpleVote() public {
        // Create a proposal
        vm.startPrank(creator);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 4 days;
        qvoting.createNewPolicy(1, "proposal1", startTime, endTime);
        vm.stopPrank();

        // Vote on the proposal
        vm.startPrank(voter1);
        vm.warp(startTime + 4 days); // Warp to voting period
        qvoting.vote(1, 2); // Vote with 2 credits (quadratic cost: 4)
        vm.stopPrank();

        // Check vote count
        QVoting.Proposal memory proposal = qvoting.getProposalDetails(1);
        assertEq(proposal.totalVotes, 2);
    }

    function testMultipleVotes() public {
        // Create a proposal
        vm.startPrank(creator);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 30 days;
        qvoting.createNewPolicy(1, "proposal1", startTime, endTime);
        vm.stopPrank();

        // Vote on the proposal with multiple voters
        vm.warp(startTime + 9 days); // Warp to voting period

        vm.startPrank(voter1);
        qvoting.vote(1, 2); // Vote with 2 credits (quadratic cost: 4)
        vm.stopPrank();

        vm.startPrank(voter2);
        qvoting.vote(1, 3); // Vote with 3 credits (quadratic cost: 9)
        vm.stopPrank();

        // Check total vote count
        QVoting.Proposal memory proposal = qvoting.getProposalDetails(1);
        assertEq(proposal.totalVotes, 5);
    }

    function testVotingPeriod() public {
        // Create a proposal
        vm.startPrank(creator);
        uint256 startTime = block.timestamp + 1 days;
        uint256 endTime = startTime + 2 days;
        qvoting.createNewPolicy(1, "proposal1", startTime, endTime);
        vm.stopPrank();

        // Try to vote before start time
        vm.startPrank(voter1);
        vm.expectRevert("Voting not allowed at this time");
        qvoting.vote(1, 2);

        // Vote during the voting period
        vm.warp(startTime + 1 days);
        qvoting.vote(1, 1);

        // Try to vote after end time
        vm.warp(endTime + 1 hours);
        vm.expectRevert("Voting not allowed at this time");
        qvoting.vote(1, 1);
        vm.stopPrank();
    }

    function testInsufficientCredits() public {
        // Create a proposal
        vm.startPrank(creator);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 10 days;
        qvoting.createNewPolicy(1, "proposal1", startTime, endTime);
        vm.stopPrank();

        // Try to vote with more credits than available
        vm.warp(startTime + 4 days);
        vm.startPrank(voter1);
        vm.expectRevert("Insufficient credits");
        qvoting.vote(1, 3); // Trying to vote with 100 credits (quadratic cost: 10000)
        vm.stopPrank();
    }
}
