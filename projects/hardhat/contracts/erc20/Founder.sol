// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./abstracts/Dividendable.sol";
import "./abstracts/Marketplace.sol";

import "hardhat/console.sol";

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

    // Virtual function that can be overridden in derived contracts
    function transferAmount(address addr, uint256 amount) public override {
        require(currencyAddress != address(0), "Currency Address has not been set");

        uint256 balance = IERC20(currencyAddress).balanceOf(address(this));
        uint256 allowance = IERC20(currencyAddress).allowance(address(this), addr);
        require(balance >= amount, "Insufficient token balance");
        require(allowance >= amount, "Insufficient allowance");

        // Transfer
        IERC20(currencyAddress).transferFrom(address(this), addr, amount);
    }

    function _balanceOfInternally(address addr) internal view override returns(uint256) {
        require(currencyAddress != address(0), "Currency Address has not been set");
        uint256 balance = IERC20(currencyAddress).balanceOf(addr);
        return balance;
    }

    function _allowanceInternally(address owner, address spender) internal view override returns(uint256) {
        require(currencyAddress != address(0), "Currency Address has not been set");
        uint256 balance = IERC20(currencyAddress).allowance(owner, spender);
        return balance;
    }

    function _transferInternally(address from, address to, uint256 amount) internal override {
        require(currencyAddress != address(0), "Currency Address has not been set");
         IERC20(currencyAddress).transferFrom(from, to, amount);
    }
}