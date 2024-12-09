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
        uint256 amount; // Amount of funds to transfer
        bool executed;
        string currencySymbol; // Currency symbol for transfer ("BNB" or ERC20)
        address targetAddress; // Address to transfer funds
    }

    uint256 public nextVoteId;
    uint256 public pendingDividends; // Track dividends reserved for ongoing votes
    mapping(uint256 => Vote) public transferVotes;

    event TransferVoteCreated(
        uint256 voteId,
        address proposer,
        string currencySymbol,
        address targetAddress,
        uint256 amount,
        string descriptionURI
    );
    event VoteExecuted(uint256 voteId, bool outcome);

    constructor(
        string memory name,
        string memory symbol
    ) Dividendable(name, symbol) {}

    // Create a vote for transferring funds
    function createTransferVote(
        string memory currencySymbol,
        address targetAddress,
        uint256 amount,
        string memory descriptionURI
    ) external {
        require(targetAddress != address(0), "Invalid target address");
        require(amount > 0, "Amount must be greater than 0");

        if (keccak256(abi.encodePacked(currencySymbol)) == keccak256(abi.encodePacked("BNB"))) {
            require(address(this).balance >= amount, "Insufficient BNB balance");
        } else {
            require(currencyExists(currencySymbol), "Currency not supported");
            require(getAvailableCurrencyBalance(currencySymbol) >= amount, "Insufficient currency balance");
        }

        uint256 voteId = nextVoteId++;
        transferVotes[voteId] = Vote({
            proposer: msg.sender,
            descriptionURI: descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 15 days,
            yesVotes: 0,
            noVotes: 0,
            amount: amount,
            executed: false,
            currencySymbol: currencySymbol,
            targetAddress: targetAddress
        });

        emit TransferVoteCreated(voteId, msg.sender, currencySymbol, targetAddress, amount, descriptionURI);
    }

    // Vote on a transfer proposal
    function vote(uint256 voteId, bool support) external {
        Vote storage voteProposal = transferVotes[voteId];
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
        Vote storage voteProposal = transferVotes[voteId];
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
        Vote storage voteProposal = transferVotes[voteId];
        require(!voteProposal.executed, "Already executed");
        voteProposal.executed = true;

        if (outcome) {
            if (keccak256(abi.encodePacked(voteProposal.currencySymbol)) == keccak256(abi.encodePacked("BNB"))) {
                _transferBNB(voteProposal.targetAddress, voteProposal.amount);
            } else {
                _transferCurrency(voteProposal.currencySymbol, voteProposal.targetAddress, voteProposal.amount);
            }
        } else {
            pendingDividends -= voteProposal.amount;
        }

        emit VoteExecuted(voteId, outcome);
    }

    // Transfer BNB
    function _transferBNB(address to, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient BNB balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "BNB transfer failed");
    }

    // Transfer ERC20 currency
    function _transferCurrency(string memory currencySymbol, address to, uint256 amount) internal {
        require(currencyExists(currencySymbol), "Currency not supported");
        IERC20 currency = IERC20(getCurrencyAddress(currencySymbol));
        require(currency.balanceOf(address(this)) >= amount, "Insufficient currency balance");

        bool success = currency.transfer(to, amount);
        require(success, "ERC20 transfer failed");
    }

    // Check if a vote can be executed immediately
    function _canExecuteVote(Vote storage voteProposal) internal view returns (bool) {
        uint256 circulatingSupply = totalSupply() - balanceOf(address(this));
        uint256 threshold = (circulatingSupply / 2) + 1;
        return voteProposal.yesVotes >= threshold || voteProposal.noVotes >= threshold;
    }

    // Check if a currency exists
    function currencyExists(string memory symbol) public view returns (bool) {
        Currency memory current = currencies[symbol];
        return (current.addr != address(0));
    }

    // Get the address of a currency by symbol
    function getCurrencyAddress(string memory symbol) public view returns (address) {
        require(currencyExists(symbol), "Currency not supported");
        return currencies[symbol].addr;
    }

    // Get available balance of a specific currency
    function getAvailableCurrencyBalance(string memory symbol) public view returns (uint256) {
        require(currencyExists(symbol), "Currency not supported");
        IERC20 currency = IERC20(getCurrencyAddress(symbol));
        return currency.balanceOf(address(this));
    }
}