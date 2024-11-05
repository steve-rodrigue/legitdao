// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

/// @custom:security-contact stev.rodr@gmail.com
interface IDependencyRequester {
    // function that requests a dependency addition
    function requestAddition(string memory dependencyKey, address dependencyAddress) external returns(uint256);

    // function that requests a dependency removal
    function requestRemoval(string memory dependencyKey, address dependencyAddress) external returns(uint256);

    // function that requests an upgrade for itself
    function requestUpgradeDependencyRequester(IDependencyRequester upgradedDependency) external returns(uint256);

    // function that verifies if a request addition was positive:
    function isRequestAdditionPositive(uint256 identifier) external view returns(address, bool, bool);

     // function that verifies if a request removal was positive:
    function isRequestRemovalPositive(uint256 identifier) external view returns(bool, bool);

    // function that verifies if a request for upgrade was positive:
    function isRequestUpgradePositive(uint256 identifier) external view returns(IDependencyRequester, bool, bool);

}