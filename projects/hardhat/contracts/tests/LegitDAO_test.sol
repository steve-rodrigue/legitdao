// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "hardhat/console.sol";

import "remix_tests.sol"; // Import Remix's testing library
import "remix_accounts.sol"; // Import to use predefined test accounts
import "../LegitDAO.sol"; // Import the LegitDAO contract
import "../IDependencyRequester.sol"; // Import the IDependencyRequester contract


// mocks:
import "./mocks/Dependency.sol";
import "./mocks/DependencyRequester.sol";

contract LegitDAOUserTest is LegitDAO {
    MockDependencyRequester mockDependencyRequester;

    /// #sender: account-0
    function beforeEach() public {
        // Deploy fresh instances of the contracts before each test
        mockDependencyRequester = new MockDependencyRequester();
    }

    /// #sender: account-1
    function testNonDeployerCannotAddDependencyRequester() public {
        try this.addDependencyRequester(mockDependencyRequester) {
            Assert.ok(false, "Dependency requester should NOT be set by non-deployer");
        } catch Error(string memory reason) {
            Assert.equal(reason, "the sender was expected to be the deployer", "Expected rejection for addDependencyRequester by non-deployer");
        }
    }
}

/// @title Unit Tests for LegitDAO Contract
/// @notice Tests for checking the functionality of LegitDAO
contract LegitDAOTest {
    MockDependencyRequester mockDependencyRequester;
    address contractAddress;
    MockDependencyRequester mockUpgradedDependencyRequester;
    string dependencyKey = "SampleDependency";
    LegitDAO legitDAO;

    /// #sender: account-0
    function beforeEach() public {
        // Deploy fresh instances of the contracts before each test
        mockDependencyRequester = new MockDependencyRequester();
        contractAddress = address(new MockDependency());
        mockUpgradedDependencyRequester = new MockDependencyRequester();

        legitDAO = new LegitDAO();
    }

    /// #sender: account-0
    function testOnlyDeployerCanAddDependencyRequester() public {
        // @annotation: Only the deployer should add a dependency requester
        legitDAO.addDependencyRequester(mockDependencyRequester);
        Assert.equal(
            address(legitDAO.dependencyRequester()),
            address(mockDependencyRequester),
            "Dependency requester should be set by deployer"
        );
    }

    /// #sender: account-0
    function testCannotRequestDependencyAdditionTwice() public {
        // @annotation: Should not allow requesting the same dependency addition twice
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestDependencyAddition(dependencyKey, contractAddress);

        try legitDAO.requestDependencyAddition(dependencyKey, contractAddress) {
            Assert.ok(false, "Should not be able to request the same dependency addition twice");
        } catch Error(string memory reason) {
            Assert.equal(reason, "the dependency already requested", "Expected rejection for duplicate addition request");
        }
    }

    /// #sender: account-0
    function testCannotRequestDependencyRemovalTwice() public {
        // @annotation: Should not allow requesting the same dependency removal twice
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestDependencyRemoval(dependencyKey, contractAddress);

        try legitDAO.requestDependencyRemoval(dependencyKey, contractAddress) {
            Assert.ok(false, "Should not be able to request the same dependency removal twice");
        } catch Error(string memory reason) {
            Assert.equal(reason, "the dependency already requested for removal", "Expected rejection for duplicate removal request");
        }
    }

    /// #sender: account-0
    function testUpdateDependenciesWithNoPendingRequests() public {
        // @annotation: Should handle updateDependencies gracefully when there are no pending requests
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.updateDependencies();

        string[] memory keys = legitDAO.getDependencyKeys();
        Assert.equal(keys.length, 0, "No dependencies should be added");
    }

    /// #sender: account-0
    function testCallFunctionWithValidKey() public {
        // set addition outcome:
        mockDependencyRequester.setAdditionOutcome(1, contractAddress, true, true);

        // @annotation: Should successfully call a function on a valid dependency
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestDependencyAddition(dependencyKey, contractAddress);
        legitDAO.updateDependencies();

        bytes memory result = legitDAO.callFunction(dependencyKey, "getValue()", "");

        Assert.notEqual(result.length, 0, "Function call should return non-empty data");
    }

    /// #sender: account-0
    function testGetDependencyAddressWithInvalidKey() public {
        // @annotation: Should revert when trying to get a dependency address with an invalid key
        try legitDAO.getDependencyAddress("InvalidKey") {
            Assert.ok(false, "Should revert when getting dependency address with invalid key");
        } catch Error(string memory reason) {
            Assert.equal(reason, "the key does NOT point to any dependency", "Expected rejection for invalid key");
        }
    }

    /// #sender: account-0
    function testCallFunctionWithInvalidKey() public {
        // @annotation: Should revert when trying to call a function with an invalid dependency key
        try legitDAO.callFunction("InvalidKey", "getValue()", "") {
            Assert.ok(false, "Should revert when calling function with invalid dependency key");
        } catch Error(string memory reason) {
            Assert.equal(reason, "The key does NOT point to any dependency", "Expected rejection for invalid key");
        }
    }

    /// #sender: account-0
    function testCannotRequestUpgradeIfPending() public {
        // @annotation: Should not allow requesting an upgrade if there is already a pending upgrade
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestUpgradeDependencyRequester(mockUpgradedDependencyRequester);

        try legitDAO.requestUpgradeDependencyRequester(mockUpgradedDependencyRequester) {
            Assert.ok(false, "Should not be able to request an upgrade if one is pending");
        } catch Error(string memory reason) {
            Assert.equal(reason, "there is already a pending upgrade in process", "Expected rejection for duplicate upgrade request");
        }
    }

    /// #sender: account-0
    function testAddDependencyRequester() public {
        // Call addDependencyRequester and check if it's successful
        legitDAO.addDependencyRequester(mockDependencyRequester);
        Assert.equal(
            address(legitDAO.dependencyRequester()),
            address(mockDependencyRequester),
            "Dependency requester should be set"
        );
    }

    /// #sender: account-0
    function testRequestDependencyAddition() public {
        // set addition outcome:
        mockDependencyRequester.setAdditionOutcome(1, contractAddress, true, true);

        // @annotation: Should successfully request a dependency addition
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestDependencyAddition(dependencyKey, contractAddress);

        uint256 identifier = legitDAO.pendingApprovalDependencies(dependencyKey);
        Assert.notEqual(identifier, 0, "Identifier should be non-zero for a valid request");
    }

   /// #sender: account-0
    function testRequestDependencyRemoval() public {
        // @annotation: Should successfully request a dependency removal
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestDependencyRemoval(dependencyKey, contractAddress);

        uint256 identifier = legitDAO.pendingRemovalDependencies(dependencyKey);
        Assert.notEqual(identifier, 0, "Identifier should be non-zero for a valid removal request");
    }

    /// #sender: account-0
    function testRequestUpgradeDependencyRequester() public {
        // @annotation: Should successfully request an upgrade
        legitDAO.addDependencyRequester(mockDependencyRequester);
        legitDAO.requestUpgradeDependencyRequester(mockUpgradedDependencyRequester);

        uint256 pendingUpgrade = legitDAO.pendingUpgradeForItself();
        Assert.notEqual(pendingUpgrade, 0, "Pending upgrade identifier should be non-zero");
    }

    /// #sender: account-0
    function testUpdateDependenciesThenCallFunction() public {
        // add the dependency requester:
        legitDAO.addDependencyRequester(mockDependencyRequester);

        // set addition outcome:
        mockDependencyRequester.setAdditionOutcome(1, contractAddress, true, true);

        string[] memory pendingKeys = legitDAO.getPendingAprovalDependencyKeys();
        Assert.equal(pendingKeys.length, 0, "Pending Aproval dependencies keys should be 1");

        // add the dependency:
        legitDAO.requestDependencyAddition(dependencyKey, contractAddress);

        string[] memory keys = legitDAO.getDependencyKeys();
        Assert.equal(keys.length, 0, "Approved dependencies keys should be 0");

        // update the dependencies:
        legitDAO.updateDependencies();

        // verify again:
        keys = legitDAO.getDependencyKeys();
        Assert.equal(keys.length, 1, "Approved dependencies keys should be 1");

        // pending should be back to 0:
        pendingKeys = legitDAO.getPendingAprovalDependencyKeys();
        Assert.equal(pendingKeys.length, 0, "Pending Aproval dependencies keys should be 0");

        // call the function:
        bytes memory data = abi.encode("getValue", "");
        bytes memory result = legitDAO.callFunction(dependencyKey, "getValue()", data);

        Assert.notEqual(result.length, 0, "Function call should return non-empty data");

        // verify the dependency address:
        address addr = legitDAO.getDependencyAddress(dependencyKey);
        Assert.equal(addr, contractAddress, "Dependency address should match the expected address");
    }
}
