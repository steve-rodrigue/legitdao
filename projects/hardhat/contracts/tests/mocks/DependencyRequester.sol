
// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

import "../../IDependencyRequester.sol";

contract MockDependencyRequester is IDependencyRequester {
    struct Request {
        address addr;
        bool isVoteFinished;
        bool isApproved;
    }

    mapping(uint256 => Request) private additionRequests;
    mapping(uint256 => Request) private removalRequests;
    mapping(uint256 => Request) private upgradeRequests;

    uint256 private additionCounter = 0;
    uint256 private removalCounter = 0;
    uint256 private upgradeCounter = 0;

    // Mock method to request a dependency addition
    function requestAddition(string memory, address) external override returns (uint256) {
        additionCounter++;
        return additionCounter;
    }

    // Mock method to request a dependency removal
    function requestRemoval(string memory, address) external override returns (uint256) {
        removalCounter++;
        return removalCounter;
    }

    // Mock method to request an upgrade
    function requestUpgradeDependencyRequester(IDependencyRequester) external override returns (uint256) {
        upgradeCounter++;
        return upgradeCounter;
    }

    // Methods to set outcomes for testing
    function setAdditionOutcome(uint256 identifier, address addr, bool isVoteFinished, bool isApproved) external {
        additionRequests[identifier] = Request(addr, isVoteFinished, isApproved);
    }

    function setRemovalOutcome(uint256 identifier, address addr, bool isVoteFinished, bool isApproved) external {
        removalRequests[identifier] = Request(addr, isVoteFinished, isApproved);
    }

    function setUpgradeOutcome(uint256 identifier, address addr, bool isVoteFinished, bool isApproved) external {
        upgradeRequests[identifier] = Request(addr, isVoteFinished, isApproved);
    }

    // Mock implementation to check if addition is positive
    function isRequestAdditionPositive(uint256 identifier) external view override returns (address, bool, bool) {
        Request memory request = additionRequests[identifier];
        return (request.addr, request.isVoteFinished, request.isApproved);
    }

    // Mock implementation to check if removal is positive
    function isRequestRemovalPositive(uint256 identifier) external view override returns (bool, bool) {
        Request memory request = removalRequests[identifier];
        return (request.isVoteFinished, request.isApproved);
    }

    // Mock implementation to check if upgrade is positive
    function isRequestUpgradePositive(uint256 identifier) external view override returns (IDependencyRequester, bool, bool) {
        Request memory request = upgradeRequests[identifier];
        return (IDependencyRequester(request.addr), request.isVoteFinished, request.isApproved);
    }
}