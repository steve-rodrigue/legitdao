// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./../abstracts/Marketplace.sol";

contract WebX is Marketplace, ERC20 {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens

    constructor() ERC20("WebX Currency", "WEBX") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Create a buy offer
    function createBuyOffer(uint256 price, uint256 amount) external payable nonReentrant {
        require(msg.value == price * amount, "Incorrect BNB sent");
        return createBuyOfferInternal(price, amount);
    }

    function _balanceOfInternally(address addr) internal view override returns(uint256) {
        return balanceOf(addr);
    }

    function _allowanceInternally(address owner, address spender) internal view override returns(uint256) {
        return allowance(owner, spender);
    }

    function _transferInternally(address from, address to, uint256 amount) internal override {
        return _transfer(from, to, amount);
    }
}