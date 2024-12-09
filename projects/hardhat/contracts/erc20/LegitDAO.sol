// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./abstracts/VotableDividend.sol";
import "./../abstracts/Marketplace.sol";
import "./../erc-721/Affiliates.sol";

contract LegitDAO is Marketplace, VotableDividend {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint256 public constant TAX_SENDER = 20; // 20%
    uint256 public constant TAX_RECEIVER = 15; // 15%

    event TransferTaxed(address indexed sender, address indexed recipient, uint256 amount);

    constructor()
        VotableDividend(150, "LegitDAO Governance Token", "LEGITDAO")
        Marketplace()
    {}

    // Override transfer to include taxation
    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(recipient != address(0), "Invalid recipient address");

        // Ensure necessary addresses are set
        require(primaryCurrencyAddress != address(0), "Primary Currency address not set");
        require(keccak256(abi.encodePacked(primaryCurrencySymbol)) != keccak256(abi.encodePacked("")), "Primary Currency symbol not set");
        require(affiliatesAddress != address(0), "Affiliates address not set");

        uint256 senderTax = (amount * TAX_SENDER) / 100; // 20% sender tax
        uint256 receiverTax = (amount * TAX_RECEIVER) / 100; // 15% receiver tax
        uint256 netAmount = amount - senderTax - receiverTax; // Net amount transferred to the recipient

        // Handle sender tax
        uint256 dividends = (senderTax * 9) / 20; // 9% to dividends
        uint256 contractAllocation = (senderTax * 10) / 20; // 10% to the contract
        uint256 burnAmount = senderTax / 20; // 1% burned

        // Allocate dividends
        _addToAdditionalContractDividends(primaryCurrencySymbol, dividends);

        // Burn the burn amount
        _burn(msg.sender, burnAmount);

        // Transfer sender tax (dividends + contractAllocation + receiverTax) to contract
        IERC20(primaryCurrencyAddress).transferFrom(msg.sender, address(this), dividends + contractAllocation + receiverTax);

        // Execute the sendPayment function on the affiliates
        _sendPaymentToAffiliates(symbol(), msg.sender, receiverTax);

        // Perform the main transfer
        bool success = super.transfer(recipient, netAmount);
        require(success, "Transfer failed");

        emit TransferTaxed(msg.sender, recipient, amount);
        return success;
    }

    // Override internal balanceOf method from Marketplace
    function _balanceOfInternally(address addr) internal view override returns (uint256) {
        require(primaryCurrencyAddress != address(0), "Primary Currency address not set");
        return IERC20(primaryCurrencyAddress).balanceOf(addr);
    }

    // Override internal allowance method from Marketplace
    function _allowanceInternally(address owner, address spender) internal view override returns (uint256) {
        require(primaryCurrencyAddress != address(0), "Primary Currency address not set");
        return IERC20(primaryCurrencyAddress).allowance(owner, spender);
    }

    // Override internal transfer method from Marketplace
    function _transferInternally(address from, address to, uint256 amount) internal override {
        require(primaryCurrencyAddress != address(0), "Primary Currency address not set");
        IERC20(primaryCurrencyAddress).transferFrom(from, to, amount);
    }

    // Override Marketplace's transferAmount for ERC-20 token transactions
    function transferAmount(address addr, uint256 amount) public override {
        require(primaryCurrencyAddress != address(0), "Primary Currency address has not been set");

        uint256 balance = IERC20(primaryCurrencyAddress).balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        bool success = IERC20(primaryCurrencyAddress).transfer(addr, amount);
        require(success, "Token transfer failed");
    }
}