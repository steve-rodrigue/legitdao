// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract NonPayableMock {
    receive() external payable {
        revert("Mock transfer failure");
    }
}