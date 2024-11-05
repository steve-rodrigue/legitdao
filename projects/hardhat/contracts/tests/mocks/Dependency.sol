
// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

contract MockDependency {
    uint256 private _value = 1;
    function getValue() view public returns(uint256) {
        return _value;
    }
}