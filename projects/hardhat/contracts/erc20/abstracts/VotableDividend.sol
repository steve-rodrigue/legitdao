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

    struct DAOVote {
        address daoAddress; // Address of the DAO contract
        bool isAdding;      // True for adding, false for removing
    }

    struct Vote {
        address proposer;
        string descriptionURI;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        uint8 voteType; // 0 = TransferVote, 1 = TokenVote, 2 = DividendVote, 3 = DAOVote
        TransferVote transferVote;
        TokenVote tokenVote;
        DividendVote dividendVote;
        DAOVote daoVote;
    }

    uint256 public nextVoteId;
    mapping(uint256 => Vote) public votes;

    // DAO Contracts
    struct DAOContract {
        string name;
        string symbol;
        address addr;
    }

    string[] public daoSymbols;
    mapping(string => DAOContract) public daoContracts;

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

    event DAOVoteCreated(
        uint256 voteId,
        address proposer,
        address daoAddress,
        bool isAdding,
        string descriptionURI
    );

    event DAOCreated(string symbol, string name, address addr);
    event DAORevoked(string symbol, address addr);
    event VoteExecuted(uint256 voteId, bool outcome);

    constructor(
        string memory name,
        string memory symbol
    ) Dividendable(name, symbol) {}

    // Create a DAO vote
    function createDAOVote(
        address daoAddress,
        string memory descriptionURI,
        bool isAdding
    ) external {
        require(daoAddress != address(0), "Invalid DAO address");

        if (isAdding) {
            require(!daoExists(daoAddress), "DAO already exists");
        } else {
            require(daoExists(daoAddress), "DAO does not exist");
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
            voteType: 3, // DAOVote
            transferVote: TransferVote("", address(0), 0), // Empty
            tokenVote: TokenVote("", address(0), false), // Empty
            dividendVote: DividendVote("", 0), // Empty
            daoVote: DAOVote(daoAddress, isAdding)
        });

        emit DAOVoteCreated(voteId, msg.sender, daoAddress, isAdding, descriptionURI);
    }

    // Utility to check if a DAO exists
    function daoExists(address daoAddress) public view returns (bool) {
        string memory symbol = ERC20(daoAddress).symbol();
        return daoContracts[symbol].addr != address(0);
    }

    // Execute a DAO vote
    function _executeDAOVote(DAOVote memory daoVote) internal {
        if (daoVote.isAdding) {
            _addDAO(daoVote.daoAddress);
        } else {
            _removeDAO(daoVote.daoAddress);
        }
    }

    // Add a DAO
    function _addDAO(address daoAddress) internal {
        require(!daoExists(daoAddress), "DAO already exists");

        ERC20 token = ERC20(daoAddress);
        string memory name = token.name();
        string memory symbol = token.symbol();

        daoContracts[symbol] = DAOContract({
            name: name,
            symbol: symbol,
            addr: daoAddress
        });

        daoSymbols.push(symbol);

        // Automatically add the DAO as a currency
        addCurrency(symbol, daoAddress);

        emit DAOCreated(symbol, name, daoAddress);
    }

    // Remove a DAO
    function _removeDAO(address daoAddress) internal {
        require(daoExists(daoAddress), "DAO does not exist");

        string memory symbol = ERC20(daoAddress).symbol();
        delete daoContracts[symbol];

        for (uint256 i = 0; i < daoSymbols.length; i++) {
            if (keccak256(abi.encodePacked(daoSymbols[i])) == keccak256(abi.encodePacked(symbol))) {
                daoSymbols[i] = daoSymbols[daoSymbols.length - 1];
                daoSymbols.pop();
                break;
            }
        }

        // Automatically revoke the DAO as a currency
        revokeCurrency(symbol);

        emit DAORevoked(symbol, daoAddress);
    }

    // Retrieve all DAOs
    function getDAOs() external view returns (DAOContract[] memory) {
        DAOContract[] memory daos = new DAOContract[](daoSymbols.length);
        for (uint256 i = 0; i < daoSymbols.length; i++) {
            daos[i] = daoContracts[daoSymbols[i]];
        }
        return daos;
    }

    // Execute a vote
    function _executeVote(uint256 voteId, bool outcome) internal {
        Vote storage voteProposal = votes[voteId];
        require(_canExecuteVote(voteProposal), "Vote treshold on proposal has not been met yet");
        
        if (outcome) {
            if (voteProposal.voteType == 0) {
                _executeTransferVote(voteProposal.transferVote);
            } else if (voteProposal.voteType == 1) {
                _executeTokenVote(voteProposal.tokenVote);
            } else if (voteProposal.voteType == 2) {
                _executeDividendVote(voteProposal.dividendVote);
            } else if (voteProposal.voteType == 3) {
                _executeDAOVote(voteProposal.daoVote);
            }
        }

        voteProposal.executed = true;
        emit VoteExecuted(voteId, outcome);
    }

    // Execute a TransferVote
    function _executeTransferVote(TransferVote memory transferVote) internal {
        require(currencyExists(transferVote.currencySymbol), "Currency does not exist");

        if (keccak256(abi.encodePacked(transferVote.currencySymbol)) == keccak256(abi.encodePacked("BNB"))) {
            _transferBNB(transferVote.targetAddress, transferVote.amount);
        } else {
            _transferCurrency(transferVote.currencySymbol, transferVote.targetAddress, transferVote.amount);
        }
    }

    // Execute a TokenVote
    function _executeTokenVote(TokenVote memory tokenVote) internal {
        if (tokenVote.isAdding) {
            addCurrency(tokenVote.currencySymbol, tokenVote.currencyAddress);
        } else {
            revokeCurrency(tokenVote.currencySymbol);
        }
    }

    // Execute a DividendVote
    function _executeDividendVote(DividendVote memory dividendVote) internal {
        require(currencyExists(dividendVote.currencySymbol), "Currency does not exist");

        uint256 availableBalance = getAvailableCurrencyBalance(dividendVote.currencySymbol);
        require(dividendVote.amount <= availableBalance, "Insufficient currency balance for dividends");

        _addToAdditionalContractDividends(dividendVote.currencySymbol, dividendVote.amount);
    }

    // Utility to check if vote can be executed
    function _canExecuteVote(Vote storage voteProposal) internal view returns (bool) {
        require(!voteProposal.executed, "Vote already executed");
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
}