// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./../abstracts/Founder.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract CurrencyFounder is Founder {
    constructor()
        Founder("LegitDAO Currency Founder", "LEGIT-CURF")
    {
        address firstTwentyFive = address(0xb2BB6301216bCe25128123EE22A23847fa80Cde7);
        address secondTwentyFive = address(0x20343F2CeBf5895c5d5707B25d0c3f526816F4dc);
        address firstFourHundredSeventyFive = address(0x5a9eD1f68865A4719a4F3928EdB2c1BbbA8655c4);
        address secondFourHundredSeventyFive = msg.sender;

        // mint 5M:
        _mint(firstTwentyFive, 2500000 * 10 ** decimals());

        // mint 5M:
        _mint(secondTwentyFive, 2500000 * 10 ** decimals());

        // mint 47.5M:
        _mint(firstFourHundredSeventyFive, 47500000 * 10 ** decimals());

        // mint 47.5M:
        _mint(secondFourHundredSeventyFive, 47500000 * 10 ** decimals());
    }
}