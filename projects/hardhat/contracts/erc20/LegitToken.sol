// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LegitToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant CONTRACT_MINT = 80_000_000 * 10**18; // 80M tokens
    uint256 public constant OWNER_MINT = 20_000_000 * 10**18; // 20M tokens
    uint256 public constant TAX_SENDER = 20; // 20% sender tax
    uint256 public constant TAX_RECEIVER = 15; // 15% receiver tax
    uint256 public totalTaxesDistributed;

    mapping(address => uint256) public withdrawnTaxes;
    mapping(address => uint256) public totalEarnedTaxes;
    mapping(address => uint256) public lastTaxesWithdrawalTime; // Track last taxes withdrawal time

    // Voting system
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => uint256)) public votes;
    uint256 voteAmount;
    address voteAddress;
    string voteReason;
    uint256 votingSession;
    uint256 public totalVotes;
    uint256 public totalVotedSupply;
    uint256 public totalDividendsDistributed;
    mapping(address => uint256) public lastDividendsWithdrawalTime; // Track last dividends withdrawal time

    mapping(address => uint256) public withdrawnDividends;
    bool public voteActive;
    uint256 public voteEndTime;
    uint256 public constant VOTE_DURATION = 7 days; // Voting lasts for 7 days

    address public affiliatesAddress;

    event WithdrawTaxes(address recipient, uint256 amount);
    event WithdrawDividends(address recipient, uint256 amount);
    event TransferTaxed(address indexed sender, address indexed recipient, uint256 amount);
    event TransferDividends(uint256 totalBNB);
    event AffiliatesAddressSet(address indexed affiliatesAddress);
    event TaxesDistributed(uint256 amount);
    event ReceiverTaxPaidToAffiliates(address indexed sender, address indexed affiliates, uint256 amount);
    event BNBReceived(address sender, uint256 amount);
    event VoteStartedDividends(uint256 endTime, uint256 amount);
    event VoteStartedTransfer(uint256 endTime, uint256 amount, address toAddress, string reason);
    event Voted(address voter, uint256 weight);

    constructor() ERC20("Legit", "LEGIT") Ownable(msg.sender) {
        _mint(address(this), CONTRACT_MINT); // Mint 80M tokens to contract
        _mint(msg.sender, OWNER_MINT); // Mint 20M tokens to owner
    }

    function tokenURI() external pure returns (string memory) {
        return "https://legitdao.com/contracts/legittoken.json";
    }

    /** 
     * @dev Set the Affiliates address, only once.
     */
    function setAffiliatesAddress(address _affiliatesAddress) public onlyOwner {
        require(affiliatesAddress == address(0), "Affiliates address already set");
        require(_affiliatesAddress != address(0), "Invalid address");
        affiliatesAddress = _affiliatesAddress;
        emit AffiliatesAddressSet(affiliatesAddress);
    }

    /** 
     * @dev Allows the contract to receive BNB.
     */
    receive() external payable {
        require(msg.value > 0, "Must send BNB");
        emit BNBReceived(msg.sender, msg.value);
    }

    /**
     * @dev Starts a vote to distribute the BNB in the contract.
     */
    function startVoteDividends(uint256 _voteAmount) external {
        require(!voteActive, "Vote already in progress");
        require(address(this).balance >= _voteAmount, "Insufficient contract BNB balance");

        voteActive = true;
        voteEndTime = block.timestamp + VOTE_DURATION;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = _voteAmount;

        emit VoteStartedDividends(voteEndTime, _voteAmount);
    }

    /**
     * @dev Starts a vote to transfer the BNB from a contract to another address
     */
    function startVoteTransfer(uint256 _voteAmount, address _toAddress, string memory _reason) external {
        require(!voteActive, "Vote already in progress");
        require(address(this).balance >= _voteAmount, "Insufficient contract BNB balance");
        require(_toAddress != address(0), "Address cannot be 0");

        voteActive = true;
        voteEndTime = block.timestamp + VOTE_DURATION;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = _voteAmount;
        voteAddress = _toAddress;
        voteReason = _reason;

        emit VoteStartedTransfer(voteEndTime, _voteAmount, _toAddress, _reason);
    }

    /**
     * @dev Allows token holders to vote pro-rata to their holdings.
     */
    function vote(bool approve) external {
        require(voteActive, "No active vote session");
        require(!hasVoted[msg.sender][votingSession], "Already voted");

        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0, "Must hold tokens to vote");

        totalVotedSupply += userBalance;

        if (approve) {
            votes[msg.sender][votingSession] = userBalance;
            totalVotes += userBalance;
        }

        hasVoted[msg.sender][votingSession] = true;
        emit Voted(msg.sender, userBalance);
    }

    /**
     * @dev Concludes the vote and distributes BNB if approved.
     */
    function concludeVote() external {
        require(voteActive, "No active vote session");
        require(block.timestamp >= voteEndTime, "Voting period not over");

        voteActive = false;

        // If at least 50% of voting power approves, distribute BNB as dividends
        if (totalVotes * 2 >= totalVotedSupply) {
            if (voteAddress != address(0)) {
                (bool success, ) = voteAddress.call{value: voteAmount}("");
                require(success, "BNB transfer failed");
            } else {
                totalDividendsDistributed += voteAmount;
            }
            
            emit TransferDividends(voteAmount);
        }

        // Reset vote data
        votingSession++;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = 0;
        voteAddress = address(0);
        voteReason = "";
    }

    /** 
     * @dev Calculate available dividends for an account.
     */
    function getAvailableDividends(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = address(account).balance;
        uint256 dividends = (totalDividendsDistributed * accountBalance) / totalSupply;
        if (dividends <= withdrawnDividends[account]) {
            return 0;
        }

        return dividends - withdrawnDividends[account];
    }

    /**
     * @dev Withdraw dividends in LegitToken, limited to once every 30 days.
     */
    function withdrawDividends() public nonReentrant {
        uint256 available = getAvailableDividends(msg.sender);
        require(available > 0, "No dividends available");

        uint256 lastWithdrawal = lastDividendsWithdrawalTime[msg.sender];
        require(block.timestamp >= lastWithdrawal + 30 days, "Withdrawal allowed once a month");

        withdrawnDividends[msg.sender] += available;
        lastDividendsWithdrawalTime[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: available}("");
        require(success, "BNB transfer failed");

        emit WithdrawDividends(msg.sender, available);
    }

    /** 
     * @dev Calculate available taxes for an account.
     */
    function getAvailableTaxes(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = balanceOf(account);
        uint256 taxes = (totalTaxesDistributed * accountBalance) / totalSupply;
        if (taxes <= withdrawnTaxes[account]) {
            return 0;
        }

        return taxes - withdrawnTaxes[account];
    }

    /**
     * @dev Withdraw taxes in LegitToken, limited to once every 30 days.
     */
    function withdrawTaxes() public nonReentrant {
        uint256 available = getAvailableTaxes(msg.sender);
        require(available > 0, "No taxes available");

        uint256 lastWithdrawal = lastTaxesWithdrawalTime[msg.sender];
        require(block.timestamp >= lastWithdrawal + 30 days, "Withdrawal allowed once a month");

        withdrawnTaxes[msg.sender] += available;
        lastTaxesWithdrawalTime[msg.sender] = block.timestamp;

        _transfer(address(this), msg.sender, available);
        emit WithdrawTaxes(msg.sender, available);
    }

    /**
     * @dev Override transfer to include taxation and tax allocations.
     */
    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(affiliatesAddress != address(0), "Affiliates address is required");

        // If sender is the affiliates contract or the contract itself, transfer without tax
        if (msg.sender == affiliatesAddress) {
            bool trxSuccess = super.transfer(recipient, amount);
            require(trxSuccess, "Transfer failed");

            emit TransferTaxed(msg.sender, recipient, amount);
            return trxSuccess;
        }

        // Apply taxes only if sender is NOT the affiliates contract
        uint256 senderTax = (amount * TAX_SENDER) / 100; // 20% sender tax
        uint256 receiverTax = (amount * TAX_RECEIVER) / 100; // 15% receiver tax
        uint256 netAmount = amount - (senderTax + receiverTax);

        uint256 taxes = (amount * 9) / 100; // 9% to taxes
        uint256 contractAllocation = (amount * 10) / 100; // 10% to contract
        uint256 burnAmount = (amount * 1) / 100; // 1% burned

        // Allocate taxes
        totalTaxesDistributed += taxes;
        emit TaxesDistributed(taxes);

        // Burn tokens
        _burn(msg.sender, burnAmount);

        // Transfer sender tax allocation to contract
        _transfer(msg.sender, address(this), contractAllocation + taxes);

        // Transfer receiver tax to affiliates
        _transfer(msg.sender, affiliatesAddress, receiverTax);
        emit ReceiverTaxPaidToAffiliates(msg.sender, affiliatesAddress, receiverTax);

        // Perform actual transfer
        bool success = super.transfer(recipient, netAmount);
        require(success, "Transfer failed");

        emit TransferTaxed(msg.sender, recipient, amount);
        return success;
    }
}