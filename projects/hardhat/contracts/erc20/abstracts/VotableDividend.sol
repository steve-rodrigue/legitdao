// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Dividendable.sol";

abstract contract VotableDividend is Dividendable {
    struct TransferVote {
        string currencySymbol; // Currency to transfer
        address targetAddress; // Address to transfer funds
        uint256 amount;        // Amount of funds to transfer
    }

    struct TokenVote {
        string currencySymbol; // Symbol of the token
        address currencyAddress; // Address of the token contract
        bool isAdding;         // True if adding, false if revoking
    }

    struct DividendVote {
        string currencySymbol; // Currency for dividends
        uint256 amount;        // Amount of dividends to distribute
    }

    struct Vote {
        address proposer;
        string descriptionURI;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        uint8 voteType; // 0 = TransferVote, 1 = TokenVote, 2 = DividendVote
        TransferVote transferVote;
        TokenVote tokenVote;
        DividendVote dividendVote;
    }

    uint256 public nextVoteId;
    mapping(uint256 => Vote) public votes;

    // Events
    event TokenVoteCreated(
        uint256 voteId,
        address proposer,
        string currencySymbol,
        bool isAdding,
        string descriptionURI
    );

    event TransferVoteCreated(
        uint256 voteId,
        address proposer,
        string currencySymbol,
        address targetAddress,
        uint256 amount,
        string descriptionURI
    );

    event DividendVoteCreated(
        uint256 voteId,
        address proposer,
        string currencySymbol,
        uint256 amount,
        string descriptionURI
    );

    // Events
    event CurrencyRevoked(string symbol);
    event BNBTransferred(address indexed target, uint256 amount);
    event CurrencyTransferred(string currencySymbol, address indexed target, uint256 amount);
    event DividendDistributed(string currencySymbol, uint256 amount);
    event VoteExecuted(uint256 voteId, bool outcome);

    constructor(
        string memory name,
        string memory symbol
    ) Dividendable(name, symbol) {}

    // Create a token vote
    function createTokenVote(
        string memory symbol,
        address currencyAddress,
        string memory descriptionURI,
        bool isAdding
    ) external {
        require(currencyAddress != address(0), "Invalid currency address");
        if (isAdding) {
            require(!currencyExists(symbol), "Token already exists");
        } else {
            require(currencyExists(symbol), "Token does not exist");
        }

        uint256 voteId = nextVoteId++;
        votes[voteId] = Vote({
            proposer: msg.sender,
            descriptionURI: descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 15 days,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            voteType: 1, // TokenVote
            transferVote: TransferVote("", address(0), 0), // Empty
            tokenVote: TokenVote(symbol, currencyAddress, isAdding),
            dividendVote: DividendVote("", 0) // Empty
        });

        emit TokenVoteCreated(voteId, msg.sender, symbol, isAdding, descriptionURI);
    }

    // Create a transfer vote
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
        votes[voteId] = Vote({
            proposer: msg.sender,
            descriptionURI: descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 15 days,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            voteType: 0, // TransferVote
            transferVote: TransferVote(currencySymbol, targetAddress, amount),
            tokenVote: TokenVote("", address(0), false), // Empty
            dividendVote: DividendVote("", 0) // Empty
        });

        emit TransferVoteCreated(voteId, msg.sender, currencySymbol, targetAddress, amount, descriptionURI);
    }

    // Create a dividend vote
    function createDividendVote(
        string memory currencySymbol,
        uint256 amount,
        string memory descriptionURI
    ) external {
        require(amount > 0, "Amount must be greater than 0");

        if (keccak256(abi.encodePacked(currencySymbol)) == keccak256(abi.encodePacked("BNB"))) {
            require(address(this).balance >= amount, "Insufficient BNB balance");
        } else {
            require(currencyExists(currencySymbol), "Currency not supported");
            require(getAvailableCurrencyBalance(currencySymbol) >= amount, "Insufficient currency balance");
        }

        uint256 voteId = nextVoteId++;
        votes[voteId] = Vote({
            proposer: msg.sender,
            descriptionURI: descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 15 days,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            voteType: 2, // DividendVote
            transferVote: TransferVote("", address(0), 0), // Empty
            tokenVote: TokenVote("", address(0), false), // Empty
            dividendVote: DividendVote(currencySymbol, amount)
        });

        emit DividendVoteCreated(voteId, msg.sender, currencySymbol, amount, descriptionURI);
    }

    // Voting logic
    function vote(uint256 voteId, bool support) external {
        Vote storage voteProposal = votes[voteId];
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

    // Finalize vote
    function finalizeVote(uint256 voteId) external {
        Vote storage voteProposal = votes[voteId];
        require(block.timestamp >= voteProposal.endTime, "Vote period not ended");
        require(!voteProposal.executed, "Vote already executed");

        if (voteProposal.yesVotes > voteProposal.noVotes) {
            _executeVote(voteId, true);
        } else {
            _executeVote(voteId, false);
        }
    }

    // Execute vote
    function _executeVote(uint256 voteId, bool outcome) internal {
        Vote storage voteProposal = votes[voteId];
        require(!voteProposal.executed, "Already executed");
        voteProposal.executed = true;

        if (outcome) {
            if (voteProposal.voteType == 0) {
                // TransferVote
                if (keccak256(abi.encodePacked(voteProposal.transferVote.currencySymbol)) == keccak256(abi.encodePacked("BNB"))) {
                    _transferBNB(voteProposal.transferVote.targetAddress, voteProposal.transferVote.amount);
                } else {
                    _transferCurrency(voteProposal.transferVote.currencySymbol, voteProposal.transferVote.targetAddress, voteProposal.transferVote.amount);
                }
            } else if (voteProposal.voteType == 1) {
                // TokenVote
                if (voteProposal.tokenVote.isAdding) {
                    addCurrency(voteProposal.tokenVote.currencySymbol, voteProposal.tokenVote.currencyAddress);
                } else {
                    revokeCurrency(voteProposal.tokenVote.currencySymbol);
                }
            } else if (voteProposal.voteType == 2) {
                // DividendVote
                _addToAdditionalContractDividends(voteProposal.dividendVote.currencySymbol, voteProposal.dividendVote.amount);
            }
        }

        emit VoteExecuted(voteId, outcome);
    }

    // Utility to check if vote can be executed
    function _canExecuteVote(Vote storage voteProposal) internal view returns (bool) {
        uint256 circulatingSupply = totalSupply() - balanceOf(address(this));
        uint256 threshold = (circulatingSupply / 2) + 1;
        return voteProposal.yesVotes >= threshold || voteProposal.noVotes >= threshold;
    }

    // Add currency
    function addCurrency(string memory symbol, address currencyAddress) internal {
        require(currencyAddress != address(0), "Invalid currency address");

        ERC20 token = ERC20(currencyAddress);
        string memory name = token.name();

        currencies[symbol] = Currency({
            name: name,
            symbol: symbol,
            addr: currencyAddress
        });

        currencySymbols.push(symbol);

        emit CurrencyAdded(symbol, name, currencyAddress);
    }

    // Revoke currency
    function revokeCurrency(string memory symbol) internal {
        require(currencyExists(symbol), "Currency does not exist");

        delete currencies[symbol];

        // Remove symbol from the array
        for (uint256 i = 0; i < currencySymbols.length; i++) {
            if (keccak256(abi.encodePacked(currencySymbols[i])) == keccak256(abi.encodePacked(symbol))) {
                currencySymbols[i] = currencySymbols[currencySymbols.length - 1];
                currencySymbols.pop();
                break;
            }
        }

        emit CurrencyRevoked(symbol);
    }

    // Check if a currency exists
    function currencyExists(string memory symbol) public view returns (bool) {
        return currencies[symbol].addr != address(0);
    }

    // Get available balance for a currency
    function getAvailableCurrencyBalance(string memory symbol) public view returns (uint256) {
        require(currencyExists(symbol), "Currency does not exist");

        address currencyAddress = currencies[symbol].addr;
        IERC20 token = IERC20(currencyAddress);

        return token.balanceOf(address(this));
    }

    // Transfer BNB
    function _transferBNB(address target, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient BNB balance");
        payable(target).transfer(amount);

        emit BNBTransferred(target, amount);
    }

    // Transfer currency
    function _transferCurrency(string memory symbol, address target, uint256 amount) internal {
        require(currencyExists(symbol), "Currency does not exist");

        address currencyAddress = currencies[symbol].addr;
        IERC20 token = IERC20(currencyAddress);

        require(token.balanceOf(address(this)) >= amount, "Insufficient currency balance");

        bool success = token.transfer(target, amount);
        require(success, "Currency transfer failed");

        emit CurrencyTransferred(symbol, target, amount);
    }
}