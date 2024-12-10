// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./../abstracts/Marketplace.sol";

contract WebX is Marketplace, ERC20 {
    uint256 public constant TOTAL_SUPPLY = 94_608_000 * 10**18; // 99,864,000 tokens with 18 decimals
    uint256 public constant MINTING_PERIOD = 20 * 365 * 4; // 20 years, 4 times per day
    uint256 public constant DIVIDER = 3240; // 1 allocation unit allows minting 1 token every 6 hours
    uint256 public immutable startTime;
    uint256 public totalMinted;
    mapping(address => uint256) public allocationPercentage;
    mapping(address => uint256) private allocatedWalletIndex; // Map wallet to its index in the array
    address[] public allocatedWallets;

    event TokenMinted(uint256 amountMinted, uint256 remainingToMint, uint256 totalMinted);
    event MintingRatioAttributed(address sender, address receiver, uint256 senderNewAmount, uint256 receiverNewAmount, uint256 transferred);

    constructor() ERC20("WebX Currency", "WEBX") {
        allocationPercentage[msg.sender] = DIVIDER;
        allocatedWallets.push(msg.sender);
        allocatedWalletIndex[msg.sender] = 0;
        startTime = block.timestamp;
    }

    function tokenURI() external pure returns (string memory) {
        return "https://legitdao.com/contracts/webx.json";
    }

    function mint() external {
        require(totalMinted < TOTAL_SUPPLY, "All tokens minted");

        // Calculate elapsed time in hours
        uint256 elapsedTime = (block.timestamp - startTime) / 3600; 
        uint256 totalMintable = (TOTAL_SUPPLY * elapsedTime) / MINTING_PERIOD;

        if (totalMintable > TOTAL_SUPPLY) {
            totalMintable = TOTAL_SUPPLY;
        }

        uint256 amountToMint = totalMintable - totalMinted;
        require(amountToMint > 0, "No new tokens to mint");

        for (uint256 i = 0; i < allocatedWallets.length; i++) {
            address wallet = allocatedWallets[i];
            uint256 walletShare = (amountToMint * allocationPercentage[wallet]) / DIVIDER;
            _mint(wallet, walletShare);
        }

        totalMinted += amountToMint;

        // Emit
        emit TokenMinted(amountToMint, (TOTAL_SUPPLY - totalMinted), totalMinted);
    }

    // Attribute minting ratio to another wallet
    function attributeMintingRatio(address to, uint256 percentage) external {
        require(to != address(0), "Cannot attribute to zero address");
        require(allocationPercentage[msg.sender] >= percentage, "Insufficient allocation to attribute");
        require(percentage > 0, "Percentage must be greater than zero");

        // Deduct from sender
        allocationPercentage[msg.sender] -= percentage;

        // Remove sender from allocatedWallets if their allocation is zero
        if (allocationPercentage[msg.sender] == 0) {
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
        if (allocationPercentage[to] == 0) {
            allocatedWallets.push(to);
            allocatedWalletIndex[to] = allocatedWallets.length - 1;
        }

        // Increment recipient's allocation
        allocationPercentage[to] += percentage;

        // Emit
        emit MintingRatioAttributed(msg.sender, to, allocationPercentage[msg.sender], allocationPercentage[to], percentage);
    }

    function allocatedWalletsLength() public view returns (uint256) {
        return allocatedWallets.length;
    }

    function remainingTokens() external view returns (uint256) {
        return TOTAL_SUPPLY - totalMinted;
    }

    function mintableTokens() external view returns (uint256) {
        // Calculate elapsed time in hours
        uint256 elapsedTime = (block.timestamp - startTime) / 3600; 
        uint256 totalMintable = (TOTAL_SUPPLY * elapsedTime) / MINTING_PERIOD;
        if (totalMintable > TOTAL_SUPPLY) {
            totalMintable = TOTAL_SUPPLY;
        }

        return totalMintable - totalMinted;
    }

    // Create a buy offer
    function createBuyOffer(uint256 price, uint256 amount) external payable nonReentrant {
        require(msg.value == price * amount, "Incorrect BNB sent");
        return createBuyOfferInternal(price, amount);
    }

    function _balanceOfInternally(address addr) internal view override returns (uint256) {
        return balanceOf(addr);
    }

    function _allowanceInternally(address owner, address spender) internal view override returns (uint256) {
        return allowance(owner, spender);
    }

    function _transferInternally(address from, address to, uint256 amount) internal override {
        return _transfer(from, to, amount);
    }
}