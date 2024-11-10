// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./../erc20/CurrencyFounder.sol";

contract MaliciousCurrencyFounderMock {
    CurrencyFounder public currencyFounder;

    constructor(address _currencyFounderAddress) {
        currencyFounder = CurrencyFounder(payable(_currencyFounderAddress));
    }

    // Fallback function that calls withdrawDividend when receiving Ether
    receive() external payable {
        currencyFounder.withdrawDividend(address(this), 1 ether);
    }

    // Function to initiate the reentrancy attack
    function attack() external {
        currencyFounder.withdrawDividend(address(this), 1 ether);
    }
}