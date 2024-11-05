// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IDependencyRequester.sol";
import "./ILegitDAO.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract LegitDAO is ILegitDAO, ReentrancyGuard {
    using Address for address;

    address public deployer;
    IDependencyRequester public dependencyRequester;
    mapping(string => address) public approvedDependencies;
    string[] public approvedDependenciesKeys;

    // pending approval dependencies:
    mapping(string => uint256) public pendingApprovalDependencies;
    string[] public pendingApprovalDependenciesKeys;

    // pending removal dependencies:
    mapping(string => uint256) public pendingRemovalDependencies;
    string[] public pendingRemovalDependenciesKeys;

    // pending upgrade for itself, one at a time:
    uint256 public pendingUpgradeForItself;

    constructor() {
        // assign the deployer:
        deployer = msg.sender;
    }

    // Function to retrieve all dependency keys
    function getDependencyKeys() external view override returns (string[] memory) {
        return approvedDependenciesKeys;
    }

    // Function to retrieve all pending approval dependency keys
    function getPendingAprovalDependencyKeys() external view override returns (string[] memory) {
        return pendingApprovalDependenciesKeys;
    }

    // Function to retrieve dependency address by key
    function getDependencyAddress(string memory keyname) external view override returns (address) {
        require(approvedDependencies[keyname] != address(0), "the key does NOT point to any dependency");
        return approvedDependencies[keyname];
    }

    // Function to add a dependency requester
    function addDependencyRequester(IDependencyRequester dependency) external override nonReentrant {
        require(msg.sender == deployer, "the sender was expected to be the deployer");

        dependencyRequester = dependency;
        emit DependencyRequesterAdded(dependencyRequester);
    }

    // Function to request a dependency addition
    function requestDependencyAddition(string memory dependencyKey, address contractAddress) external override nonReentrant {
        require(address(dependencyRequester) != address(0), "the dependency requester is not set");
        require(address(contractAddress) != address(0), "the contract address is not set");
        uint256 identifier = dependencyRequester.requestAddition(dependencyKey, contractAddress);

        require(pendingApprovalDependencies[dependencyKey] == 0, "the dependency already requested");

        pendingApprovalDependencies[dependencyKey] = identifier;
        pendingApprovalDependenciesKeys.push(dependencyKey);

        emit DependencyAdditionRequested(dependencyKey, contractAddress);
    }

    // Function to request a dependency removal
    function requestDependencyRemoval(string memory dependencyKey, address contractAddress) external override nonReentrant {
        require(address(dependencyRequester) != address(0), "the dependency requester is not set");
        require(address(contractAddress) != address(0), "the contract address is not set");
        uint256 identifier = dependencyRequester.requestRemoval(dependencyKey, contractAddress);

        require(pendingRemovalDependencies[dependencyKey] == 0, "the dependency already requested for removal");

        pendingRemovalDependencies[dependencyKey] = identifier;
        pendingRemovalDependenciesKeys.push(dependencyKey);

        emit DependencyRemovalRequested(dependencyKey, contractAddress);
    }

    // Function to request an upgrade for the dependency requester
    function requestUpgradeDependencyRequester(IDependencyRequester upgradedDependencyRequester) external override nonReentrant {
        require(pendingUpgradeForItself == 0, "there is already a pending upgrade in process");
        require(address(dependencyRequester) != address(0), "the dependency requester is not set");

        uint256 identifier = dependencyRequester.requestUpgradeDependencyRequester(upgradedDependencyRequester);
        pendingUpgradeForItself = identifier;

        emit DependencyRequesterUpgradeRequested(upgradedDependencyRequester);
    }

    // Function to update dependencies
    function updateDependencies() external override nonReentrant {
        require(address(dependencyRequester) != address(0), "the dependency requester is not set");

        // Process any pending upgrade request
        if (pendingUpgradeForItself > 0) {
            (IDependencyRequester contractIns, bool isVoteFinished, bool isApproved) = dependencyRequester.isRequestUpgradePositive(pendingUpgradeForItself);
            if (isVoteFinished) {
                pendingUpgradeForItself = 0;
            }

            if (isVoteFinished && isApproved) {
                emit DependencyRequesterUpgraded(contractIns);
            }

            if (isVoteFinished && !isApproved) {
                emit DependencyRequesterUpgradeFailed(contractIns);
            }
        }

        // Process pending removals
        if (pendingRemovalDependenciesKeys.length > 0) {
            for (uint256 i = pendingRemovalDependenciesKeys.length; i > 0; i--) {
                uint256 index = i - 1;
                string memory keyname = pendingRemovalDependenciesKeys[index];
                uint256 identifier = pendingRemovalDependencies[keyname];

                (bool isVoteFinished, bool isApproved) = dependencyRequester.isRequestRemovalPositive(identifier);
                if (!isVoteFinished) {
                    continue;
                }

                address dependencyAddress = approvedDependencies[keyname];
                if (isApproved) {
                    delete approvedDependencies[keyname];

                    // re-order the array then pop it:
                    approvedDependenciesKeys[index] = approvedDependenciesKeys[approvedDependenciesKeys.length - 1];
                    approvedDependenciesKeys.pop();

                    // emit the event:
                    emit DependencyRemoved(keyname, dependencyAddress);
                }

                if (!isApproved) {
                    emit DependencyRemovalFailed(keyname, dependencyAddress);
                }

                delete pendingRemovalDependencies[keyname];
                pendingRemovalDependenciesKeys[index] = pendingRemovalDependenciesKeys[pendingRemovalDependenciesKeys.length - 1];
                pendingRemovalDependenciesKeys.pop();
            }
        }

        // Process pending additions
        if (pendingApprovalDependenciesKeys.length > 0) {
            for (uint256 i = pendingApprovalDependenciesKeys.length; i > 0; i--) {
                uint256 index = i - 1;
                string memory keyname = pendingApprovalDependenciesKeys[index];
                uint256 identifier = pendingApprovalDependencies[keyname];

                (address addr, bool isVoteFinished, bool isApproved) = dependencyRequester.isRequestAdditionPositive(identifier);
                if (!isVoteFinished) {
                    continue;
                }

                if (isApproved) {
                    approvedDependencies[keyname] = addr;
                    approvedDependenciesKeys.push(keyname);
                    emit DependencyAdded(keyname, addr);
                }

                if (!isApproved) {
                    emit DependencyAdditionFailed(keyname, addr);
                }

                delete pendingApprovalDependencies[keyname];
                pendingApprovalDependenciesKeys[index] = pendingApprovalDependenciesKeys[pendingApprovalDependenciesKeys.length - 1];
                pendingApprovalDependenciesKeys.pop();
            }
        }
    }

    // Function to call a method dynamically using the function selector
    function callFunction(string memory dependencyKey, string memory functionSignature, bytes memory data) external override nonReentrant returns (bytes memory) {
        address dependencyAddress = _getAddress(dependencyKey);
        bytes4 selector = _getSelector(functionSignature);
        return _callFunctionOnDependency(dependencyAddress, selector, data);
    }

    function _callFunctionOnDependency(address dependency, bytes4 selector, bytes memory data) private returns (bytes memory) {
        bytes memory callData = abi.encodePacked(selector, data);
        return dependency.functionCall(callData);
    }

    function _getSelector(string memory functionSignature) private pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionSignature)));
    }

    function _getAddress(string memory dependencyKey) private view returns (address) {
        require(approvedDependencies[dependencyKey] != address(0), "The key does NOT point to any dependency");
        return approvedDependencies[dependencyKey];
    }
}