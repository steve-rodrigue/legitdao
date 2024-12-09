// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Dividendable.sol";

abstract contract VotableDividend is Dividendable {
    struct Vote {
        address proposer;
        string descriptionURI;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 amount; // Amount of dividends to handle
        bool executed;
    }

    struct TransferVote {
        Vote vote;
        address targetAddress; // Address to transfer funds
    }

    uint256 public nextVoteId;
    uint256 public pendingDividends; // Track dividends reserved for ongoing votes
    mapping(uint256 => Vote) public dividendVotes;
    mapping(uint256 => TransferVote) public transferVotes;

    event DividendVoteCreated(uint256 voteId, address proposer, uint256 amount, string descriptionURI);
    event TransferVoteCreated(uint256 voteId, address proposer, address targetAddress, uint256 amount, string descriptionURI);
    event VoteExecuted(uint256 voteId, bool outcome);

    constructor(
        string memory name, 
        string memory symbol
    ) 
        Dividendable( name, symbol)  
    {}

    // Create a vote for dividend distribution
    function createDividendVote(uint256 amount, string memory descriptionURI) external {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= totalDividendsAvailable() - pendingDividends, "Insufficient available dividends");

        pendingDividends += amount;

        uint256 voteId = nextVoteId++;
        dividendVotes[voteId] = Vote({
            proposer: msg.sender,
            descriptionURI: descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 15 days,
            yesVotes: 0,
            noVotes: 0,
            amount: amount,
            executed: false
        });

        emit DividendVoteCreated(voteId, msg.sender, amount, descriptionURI);
    }

    // Create a vote for transferring funds
    function createTransferVote(
        address targetAddress,
        uint256 amount,
        string memory descriptionURI
    ) external {
        require(targetAddress != address(0), "Invalid target address");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= totalDividendsAvailable() - pendingDividends, "Insufficient available dividends");

        pendingDividends += amount;

        uint256 voteId = nextVoteId++;
        transferVotes[voteId] = TransferVote({
            vote: Vote({
                proposer: msg.sender,
                descriptionURI: descriptionURI,
                startTime: block.timestamp,
                endTime: block.timestamp + 15 days,
                yesVotes: 0,
                noVotes: 0,
                amount: amount,
                executed: false
            }),
            targetAddress: targetAddress
        });

        emit TransferVoteCreated(voteId, msg.sender, targetAddress, amount, descriptionURI);
    }

    // Vote on a dividend or transfer proposal
    function vote(uint256 voteId, bool support) external {
        Vote storage voteProposal;
        if (dividendVotes[voteId].startTime > 0) {
            voteProposal = dividendVotes[voteId];
        } else if (transferVotes[voteId].vote.startTime > 0) {
            voteProposal = transferVotes[voteId].vote;
        } else {
            revert("Invalid vote ID");
        }

        require(block.timestamp < voteProposal.endTime, "Vote period ended");
        require(!voteProposal.executed, "Vote already executed");

        uint256 weight = balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            voteProposal.yesVotes += weight;
        } else {
            voteProposal.noVotes += weight;
        }

        // Check if vote can be executed immediately
        if (_canExecuteVote(voteProposal)) {
            _executeVote(voteId, true);
        }
    }

    // Finalize vote after the period ends
    function finalizeVote(uint256 voteId) external {
        Vote storage voteProposal;
        bool isDividendVote = false;

        if (dividendVotes[voteId].startTime > 0) {
            voteProposal = dividendVotes[voteId];
            isDividendVote = true;
        } else if (transferVotes[voteId].vote.startTime > 0) {
            voteProposal = transferVotes[voteId].vote;
        } else {
            revert("Invalid vote ID");
        }

        require(block.timestamp >= voteProposal.endTime, "Vote period not ended");
        require(!voteProposal.executed, "Vote already executed");

        if (voteProposal.yesVotes > voteProposal.noVotes) {
            _executeVote(voteId, true);
        } else {
            _executeVote(voteId, false);
        }
    }

    // Execute a vote
    function _executeVote(uint256 voteId, bool outcome) internal {
        Vote storage voteProposal;
        bool isDividendVote = false;

        if (dividendVotes[voteId].startTime > 0) {
            voteProposal = dividendVotes[voteId];
            isDividendVote = true;
        } else if (transferVotes[voteId].vote.startTime > 0) {
            voteProposal = transferVotes[voteId].vote;
        } else {
            revert("Invalid vote ID");
        }

        require(!voteProposal.executed, "Already executed");
        voteProposal.executed = true;

        if (outcome) {
            if (isDividendVote) {
                _addToAdditionalContractDividends(voteProposal.amount);
            } else {
                TransferVote storage transferVote = transferVotes[voteId];
                _transferCurrencyFromContract(transferVote.targetAddress, voteProposal.amount);
            }
        } else {
            pendingDividends -= voteProposal.amount;
        }

        emit VoteExecuted(voteId, outcome);
    }

    // Check if a vote can be executed immediately
    function _canExecuteVote(Vote storage voteProposal) internal view returns (bool) {
        uint256 circulatingSupply = totalSupply() - balanceOf(address(this));
        uint256 threshold = (circulatingSupply / 2) + 1;
        return voteProposal.yesVotes >= threshold || voteProposal.noVotes >= threshold;
    }
}