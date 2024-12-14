// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WebX is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 94_608_000 * 10**18;
    uint256 public constant MINTING_PERIOD = 20 * 365 * 4; // 20 years, 4 times per day
    uint256 public constant TOKENS_PER_PERIOD = 3240 * 10**18;
    uint256 public constant AMOUNT_OF_SECOND_PER_PERIOD = 21600; // 6 hours
    uint256 public lastMintedTime;
    uint256 public immutable startTime;
    uint256 public totalMinted;
    mapping(address => uint256) public allocationBlocks;
    mapping(address => uint256) private allocatedWalletIndex; // Map wallet to its index in the array
    address[] public allocatedWallets;

    event TokenMinted(uint256 amountMinted, uint256 remainingToMint, uint256 totalMinted);
    event MintingRatioAttributed(address sender, address receiver, uint256 senderNewAmount, uint256 receiverNewAmount, uint256 transferred);

    constructor() ERC20("WebX2", "WEBX2") {
        allocationBlocks[msg.sender] = TOKENS_PER_PERIOD;
        allocatedWallets.push(msg.sender);
        allocatedWalletIndex[msg.sender] = 0;
        startTime = block.timestamp;
        lastMintedTime = startTime;
    }

    function tokenURI() external pure returns (string memory) {
        return "https://legitdao.com/contracts/webx.json";
    }

    function mint() external {
        require(totalMinted < TOTAL_SUPPLY, "All tokens minted");

        // Calculate elapsed time in hours
        uint256 currentTime = block.timestamp;
        uint256 amountToMint = mintableTokens();
        require(amountToMint > 0, "No Token to mint");

        for (uint256 i = 0; i < allocatedWallets.length; i++) {
            address wallet = allocatedWallets[i];
            uint256 walletShare = (amountToMint * allocationBlocks[wallet]) / TOKENS_PER_PERIOD;
            _mint(wallet, walletShare);
        }

        totalMinted += amountToMint;
        lastMintedTime = currentTime;

        // Emit
        emit TokenMinted(amountToMint, (TOTAL_SUPPLY - totalMinted), totalMinted);
    }

    // Attribute minting ratio to another wallet
    function attributeMintingBlock(address to, uint256 amountBlock) external {
        require(to != address(0), "Cannot attribute to zero address");
        require(amountBlock > 0, "amountBlock must be greater than zero");
        
        uint256 amountBlockInWei = blocksWorthInWei(amountBlock);
        require(allocationBlocks[msg.sender] >= amountBlockInWei, "Insufficient allocation to attribute");

        // Deduct from sender
        allocationBlocks[msg.sender] -= amountBlockInWei;

        // Remove sender from allocatedWallets if their allocation is zero
        if (allocationBlocks[msg.sender] == 0) {
            uint256 senderIndex = allocatedWalletIndex[msg.sender];
            uint256 lastIndex = allocatedWallets.length - 1;

            if (senderIndex != lastIndex) {
                address lastWallet = allocatedWallets[lastIndex];
                allocatedWallets[senderIndex] = lastWallet; // Replace sender with last wallet
                allocatedWalletIndex[lastWallet] = senderIndex; // Update index of last wallet
            }

            allocatedWallets.pop(); // Remove last wallet
            delete allocatedWalletIndex[msg.sender]; // Clean up index mapping
        }

        // Add recipient to allocatedWallets if not already present
        if (allocationBlocks[to] == 0) {
            allocatedWallets.push(to);
            allocatedWalletIndex[to] = allocatedWallets.length - 1;
        }

        // Increment recipient's allocation
        allocationBlocks[to] += amountBlockInWei;

        // Emit
        emit MintingRatioAttributed(msg.sender, to, allocationBlocks[msg.sender], allocationBlocks[to], amountBlockInWei);
    }

    function allocatedWalletsLength() public view returns (uint256) {
        return allocatedWallets.length;
    }

    function remainingTokens() external view returns (uint256) {
        return TOTAL_SUPPLY - totalMinted;
    }

    function mintableTokens() public view returns (uint256) {
        // All supply has been minted
        if (totalMinted >= TOTAL_SUPPLY) {
            return 0;
        }

        // Not eneough time to cover 1 period
        uint256 amountOfPeriods = (block.timestamp - startTime) / AMOUNT_OF_SECOND_PER_PERIOD;
        uint256 amountToMint = amountOfPeriods * TOKENS_PER_PERIOD;
        return amountToMint - totalMinted;
    }

    function getAllocatedBlocks(address addr) external view returns(uint256) {
        uint256 oneBlockWorthInWei = blocksWorthInWei(1);
        if (allocationBlocks[addr] <= oneBlockWorthInWei) {
            return 0;
        }

        return allocationBlocks[addr] / oneBlockWorthInWei;
    }

    function balanceOfInToken(address addr) external view returns(uint256) {
        uint256 balance = balanceOf(addr);
        uint256 oneTokenInWei = blocksWorthInWei(1);
        if (balance <= oneTokenInWei) {
            return 0;
        }

        return balance / oneTokenInWei;
    }

    function blocksWorthInWei(uint256 amount) public pure returns(uint256) {
        return amount * 10**18;
    }
}