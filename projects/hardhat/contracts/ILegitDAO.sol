// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "./IDependencyRequester.sol";

interface ILegitDAO {
    function getDependencyKeys() external view returns (string[] memory);
    function getDependencyAddress(string memory keyname) external view returns (address);
    function getPendingAprovalDependencyKeys() external view returns (string[] memory);
    function addDependencyRequester(IDependencyRequester dependencyAddress) external;
    function requestDependencyAddition(string memory dependencyKey, address contractAddress) external;
    function requestDependencyRemoval(string memory dependencyKey, address contractAddress) external;
    function requestUpgradeDependencyRequester(IDependencyRequester upgradedDependencyRequester) external;
    function updateDependencies() external;
    function callFunction(string memory dependencyKey, string memory functionSignature, bytes memory data) external returns (bytes memory);

    // events:
    event DependencyRequesterAdded(IDependencyRequester indexed contractAddress);
    event DependencyRequesterUpgradeRequested(IDependencyRequester indexed contractInstance);
    event DependencyRequesterUpgraded(IDependencyRequester indexed contractInstance);
    event DependencyRequesterUpgradeFailed(IDependencyRequester indexed contractAddress);
    event DependencyAdditionRequested(string dependencyKey, address indexed contractAddress);
    event DependencyAdded(string dependencyKey, address indexed contractAddress);
    event DependencyAdditionFailed(string dependencyKey, address indexed contractAddress);
    event DependencyRemovalRequested(string dependencyKey, address indexed contractAddress);
    event DependencyRemoved(string dependencyKey, address indexed contractAddress);
    event DependencyRemovalFailed(string dependencyKey, address indexed contractAddress);
}