// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./../abstracts/Founder.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract DAOFounder is Founder {
    constructor()
        Founder("LegitDAO Founder", "LEGIT-FDR")
    {

        // mint equally:
        _mint(address(0x8A85c533693a87837380d9225d226e334663d104), 16666666 * 10 ** decimals());
        _mint(address(0xEF626c6425A2b077c23c2d747FCfE65777F66B10), 16666666 * 10 ** decimals());
        _mint(address(0xceaE30276B9fD5FA44366167e64728180eb3962c), 16666666 * 10 ** decimals());
        _mint(address(0x1349DCDd92BA65Cf2234eD8c61C72DdF1f95400E), 16666666 * 10 ** decimals());
        _mint(address(0xacd745EB1F708C323C2167966fcA4503430705E1), 16666666 * 10 ** decimals());
        _mint(msg.sender, 16666670 * 10 ** decimals());
    }
}