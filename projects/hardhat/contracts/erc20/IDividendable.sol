// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

interface IDividendable {
    function withdrawDividend(address sendTo, uint256 amount) external;
    function getDividendAmount(address addr) external view returns (uint256);

    // events:
    event PaymentReceivedInContract(address indexed user, uint256 amount);
    event DividendWithdrawn(address indexed user, uint256 amount);
}