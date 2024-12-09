// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./abstracts/Dividendable.sol";
import "./abstracts/Marketplace.sol";

contract Founder is Marketplace, Dividendable {
    constructor(
        address[] memory holders
    )
        Dividendable("LegitDAO Founder Token", "LEGITDAO_F") 
        Marketplace()
    {
        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], 10_000_000 * 10 ** decimals());
        }
    }

    // Transfer amount to an address in the specified currency
    function transferAmount(address addr, uint256 amount) public override {
        require(primaryCurrencyAddress != address(0), "Primary Currency Address has not been set");

        IERC20 token = IERC20(primaryCurrencyAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        // Transfer
        bool success = token.transfer(addr, amount);
        require(success, "Token transfer failed");
    }

    // Get internal balance of an address for a specific currency
    function _balanceOfInternally(address addr) internal view override returns (uint256) {
        string memory defaultCurrencySymbol = currencySymbols[0];
        require(currencies[defaultCurrencySymbol].addr != address(0), "Currency Address has not been set");
        return IERC20(currencies[defaultCurrencySymbol].addr).balanceOf(addr);
    }

    // Get internal allowance of an address for a specific currency
    function _allowanceInternally(address owner, address spender) internal view override returns (uint256) {
        string memory defaultCurrencySymbol = currencySymbols[0];
        require(currencies[defaultCurrencySymbol].addr != address(0), "Currency Address has not been set");
        return IERC20(currencies[defaultCurrencySymbol].addr).allowance(owner, spender);
    }

    // Internal transfer function for a specific currency
    function _transferInternally(address from, address to, uint256 amount) internal override {
        string memory defaultCurrencySymbol = currencySymbols[0];
        require(currencies[defaultCurrencySymbol].addr != address(0), "Currency Address has not been set");

        IERC20 token = IERC20(currencies[defaultCurrencySymbol].addr);
        require(token.allowance(from, address(this)) >= amount, "Insufficient allowance");

        bool success = token.transferFrom(from, to, amount);
        require(success, "Token transfer failed");
    }
}