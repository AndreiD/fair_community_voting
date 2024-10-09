// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract QVoting is ReentrancyGuard, AccessControl {
    string public version = "0.0.1";

    uint256 public constant CREDITS_PER_DAY = 1; // Credits earned per day

    // Roles for managing proposal creation, address registration, and policy blocking
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant REGISTER_ROLE = keccak256("REGISTER_ROLE");
    bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");

    struct Proposal {
        string proposalHash; // Hash of the proposal's text
        uint256 totalVotes; // Total quadratic votes for the proposal
        uint256 groupID; // Group ID associated with the proposal
        uint256 createdAt; // Proposal creation time (UNIX timestamp)
        uint256 startTime; // Proposal start time (UNIX timestamp)
        uint256 endTime; // Proposal end time (UNIX timestamp)
        bool isProposalBlocked; // Flag to block voting on this proposal
        string blockReason; // Reason for blocking the proposal
    }

    struct Voter {
        uint256 groupID; // the group the voter is part of
        uint256 totalCreditsUsed; //total credits used
        uint256 registrationTime; // Time when the voter registered (UNIX timestamp)
        bool isBlocked; // Flag to block the voter
        string blockReason; // Reason for blocking the voter
    }

    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal details
    mapping(address => Voter) public voters; // Voter address => Voter details
    mapping(bytes32 => bool) public hasVotedOnProposal; // Voter address + Proposal ID => voted status
    mapping(address => uint256) public lastVoted; // Last vote timestamp for voter
    uint256 public minIntervalBetweenVotes = 5 seconds; // Minimum time between votes for a user

    mapping(address => uint256) public groupForAddress; // Group ID for each address (0 = public)
    mapping(address => bool) public registered; // Whether an address is registered

    uint256 private startIndex = 0;

    event NewProposal(string hash, uint256 groupID);
    event Voted(uint256 proposalID, uint256 groupID, uint256 totalVotes);
    event UnVoted(uint256 proposalID, uint256 groupID, uint256 totalVotes);
    event Blocked(address user, bool isBlocked, string reason);
    event ProposalBlocked(uint256 proposalID, bool isBlocked, string reason);

    /**
     * @notice Contract constructor to assign initial roles
     * @param creator The address allowed to create policies
     * @param blocker The address allowed to block users or proposals
     * @param register The address allowed to register users
     */
    constructor(address creator, address blocker, address register) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CREATOR_ROLE, creator);
        _grantRole(BLOCKER_ROLE, blocker);
        _grantRole(REGISTER_ROLE, register);
    }

    /**
     * @notice Registers or unregisters an address in the system
     * @dev Assigns the user to a group and registers their address
     * @param newAddress The address of the user to register
     * @param groupID The group ID the user belongs to (0 for no group)
     */
    function registerAddress(address newAddress, uint256 groupID) external onlyRole(REGISTER_ROLE) {
        require(groupID > 0, "Invalid group ID"); // Ensure groupID is valid
        registered[newAddress] = true;

        voters[newAddress] = Voter({
            registrationTime: block.timestamp,
            totalCreditsUsed: 0,
            groupID: groupID,
            isBlocked: false,
            blockReason: ""
        });
    }

    /**
     * @notice Creates a new policy (proposal)
     * @dev Can only be called by users with the CREATOR_ROLE
     * @param groupID The group ID associated with the proposal
     * @param bodyHash The hash of the proposal content
     * @param startTime The start time (UNIX timestamp) of the voting period
     * @param endTime The end time (UNIX timestamp) of the voting period
     */
    function createNewPolicy(uint256 groupID, string memory bodyHash, uint256 startTime, uint256 endTime)
        external
        onlyRole(CREATOR_ROLE)
    {
        require(startTime < endTime, "Invalid proposal time range.");

        startIndex += 1;

        proposals[startIndex] = Proposal({
            proposalHash: bodyHash,
            groupID: groupID,
            totalVotes: 0,
            createdAt: block.timestamp,
            startTime: startTime,
            endTime: endTime,
            isProposalBlocked: false,
            blockReason: ""
        });

        emit NewProposal(bodyHash, groupID);
    }

    /**
     * @notice Casts a quadratic vote on a proposal
     * @dev Uses quadratic voting where the cost of votes is squared
     * @param proposalID The ID of the proposal to vote on
     * @param votesAllocated The number of votes to allocate
     */
    function vote(uint256 proposalID, uint256 votesAllocated) external nonReentrant {
        Proposal memory proposal = proposals[proposalID];
        Voter storage voter = voters[msg.sender];

        require(registered[msg.sender], "Address not registered");
        require(votesAllocated > 0, "invalid votes allocated");
        require(proposal.createdAt != 0, "Proposal not found");
        require(!voter.isBlocked, "Blocked from voting");
        require(
            block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime,
            "Voting not allowed at this time"
        );
        require(!proposal.isProposalBlocked, "Proposal is blocked from voting");
        require(proposal.groupID == voter.groupID, "Can only vote on proposals in your group");

        uint256 availableCredits = calculateAvailableCredits(msg.sender);

        require(availableCredits >= votesAllocated * votesAllocated, "Insufficient credits");
        require(block.timestamp >= lastVoted[msg.sender] + minIntervalBetweenVotes, "Must wait between votes");

        bytes32 keyVoted = keccak256(abi.encodePacked(msg.sender, proposalID));
        require(!hasVotedOnProposal[keyVoted], "Already voted");

        uint256 voteCost = votesAllocated * votesAllocated;
        voter.totalCreditsUsed += voteCost; // Track used credits

        // Mark as has voted
        hasVotedOnProposal[keyVoted] = true;

        // Set last voted time
        lastVoted[msg.sender] = block.timestamp;

        // Increment total votes
        proposals[proposalID].totalVotes += votesAllocated;

        emit Voted(proposalID, proposal.groupID, proposals[proposalID].totalVotes);
    }

    /**
     * @notice Removes a vote from a proposal
     * @dev Allows users to undo their vote before the voting period ends
     * @param proposalID The ID of the proposal to unvote
     * @param votesAllocated The number of votes to retract
     */
    function unvote(uint256 proposalID, uint256 votesAllocated) external nonReentrant {
        Voter storage voter = voters[msg.sender];
        Proposal memory proposal = proposals[proposalID];

        require(registered[msg.sender], "Address not registered");
        require(votesAllocated > 0, "invalid votes allocated");
        require(!proposal.isProposalBlocked, "Proposal is blocked from unvoting");
        require(proposal.groupID == groupForAddress[msg.sender], "Can only unvote proposals in your group");
        require(!voter.isBlocked, "Blocked from voting");
        require(
            block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime,
            "Unvoting not allowed at this time"
        );

        bytes32 keyVoted = keccak256(abi.encodePacked(msg.sender, proposalID));
        require(hasVotedOnProposal[keyVoted], "Not voted");

        // Quadratic unvote cost
        uint256 voteCost = votesAllocated * votesAllocated;
        voter.totalCreditsUsed -= voteCost; // Track used credits decrease

        // Mark as has not voted
        hasVotedOnProposal[keyVoted] = false;

        // Update last vote time
        lastVoted[msg.sender] = block.timestamp;

        // Decrease total votes
        proposals[proposalID].totalVotes -= votesAllocated;

        emit UnVoted(proposalID, proposal.groupID, proposals[proposalID].totalVotes);
    }

    /**
     * @notice Blocks or unblocks a proposal
     * @dev Admin function to restrict voting on a proposal
     * @param proposalID The ID of the proposal to block or unblock
     * @param blacklisted True to block the proposal, false to unblock
     * @param reason The reason for blocking or unblocking the proposal
     */
    function setPolicyBlock(uint256 proposalID, bool blacklisted, string memory reason)
        external
        onlyRole(BLOCKER_ROLE)
    {
        proposals[proposalID].isProposalBlocked = blacklisted;
        proposals[proposalID].blockReason = reason;
        emit ProposalBlocked(proposalID, blacklisted, reason);
    }

    /**
     * @notice Blocks or unblocks a user
     * @dev Admin function to restrict voting by a user
     * @param user The address of the user to block or unblock
     * @param isBlocked True to block the user, false to unblock
     * @param reason The reason for blocking or unblocking the user
     */
    function setUserBlock(address user, bool isBlocked, string memory reason) external onlyRole(BLOCKER_ROLE) {
        voters[user].isBlocked = isBlocked;
        voters[user].blockReason = reason;
        emit Blocked(user, isBlocked, reason);
    }

    /**
     * @notice Sets the minimum interval between votes
     * @dev Can only be called by the default admin role
     * @param newMinInterval The new minimum time (in seconds) between votes
     */
    function setMinIntervalBetweenVotes(uint256 newMinInterval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minIntervalBetweenVotes = newMinInterval;
    }

    /**
     * @notice Retrieves the details of a proposal
     * @param proposalID The ID of the proposal to fetch
     * @return Proposal The full details of the specified proposal
     */
    function getProposalDetails(uint256 proposalID) public view returns (Proposal memory) {
        return proposals[proposalID];
    }

    /**
     * @notice Calculates available credits based on registration time and used credits
     * @param voterAddress The address of the voter
     * @return uint256 The total available credits for the voter
     */
    function calculateAvailableCredits(address voterAddress) public view returns (uint256) {
        Voter storage voter = voters[voterAddress];

        // Calculate the days since registration
        uint256 daysSinceRegistration = (block.timestamp - voter.registrationTime) / 1 days;
        uint256 earnedCredits = daysSinceRegistration * CREDITS_PER_DAY; // Total credits based on days

        // Calculate available credits by subtracting used credits from earned credits
        return earnedCredits >= voter.totalCreditsUsed ? (earnedCredits - voter.totalCreditsUsed) : 0;
    }
}
