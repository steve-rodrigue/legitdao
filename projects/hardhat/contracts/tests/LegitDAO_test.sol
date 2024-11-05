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

/// @title Unit Tests for LegitDAO Contract
/// @notice Tests for checking the functionality of LegitDAO
contract LegitDAOTest {
    LegitDAO legitDAO;
    address deployer;
    address nonDeployer;
    MockDependencyRequester dependencyRequester;
    address contractAddress;
    MockDependencyRequester upgradedDependencyRequester;

    string dependencyKey = "SampleDependency";

    /// #sender: account-0
    function beforeAll() public {
        // Initialize accounts:
        deployer = TestsAccounts.getAccount(0); // Test account 0
        nonDeployer = TestsAccounts.getAccount(1); // Test account 1
        
    }

    /// #sender: account-0
    function beforeEach() public {
        // Deploy fresh instances of the contracts before each test
        dependencyRequester = new MockDependencyRequester();
        contractAddress = address(new MockDependency());
        upgradedDependencyRequester = new MockDependencyRequester();
        legitDAO = new LegitDAO();
    }

    /// #sender: account-0
    function testAddDependencyRequester() public {
        // @annotation: Only the deployer should add a dependency requester
        Assert.equal(msg.sender, deployer, "The deployer should be msg.sender");

        // Call addDependencyRequester and check if it's successful
        legitDAO.addDependencyRequester(dependencyRequester);
        Assert.equal(
            address(legitDAO.dependencyRequester()),
            address(dependencyRequester),
            "Dependency requester should be set"
        );
    }

    /// #sender: account-0
    function testRequestDependencyAddition() public {
        // set addition outcome:
        dependencyRequester.setAdditionOutcome(1, contractAddress, true, true);

        // @annotation: Should successfully request a dependency addition
        legitDAO.addDependencyRequester(dependencyRequester);
        legitDAO.requestDependencyAddition(dependencyKey, contractAddress);

        uint256 identifier = legitDAO.pendingApprovalDependencies(dependencyKey);
        Assert.notEqual(identifier, 0, "Identifier should be non-zero for a valid request");
    }

   /// #sender: account-0
    function testRequestDependencyRemoval() public {
        // @annotation: Should successfully request a dependency removal
        legitDAO.addDependencyRequester(dependencyRequester);
        legitDAO.requestDependencyRemoval(dependencyKey, contractAddress);

        uint256 identifier = legitDAO.pendingRemovalDependencies(dependencyKey);
        Assert.notEqual(identifier, 0, "Identifier should be non-zero for a valid removal request");
    }

    /// #sender: account-0
    function testRequestUpgradeDependencyRequester() public {
        // @annotation: Should successfully request an upgrade
        legitDAO.addDependencyRequester(dependencyRequester);
        legitDAO.requestUpgradeDependencyRequester(upgradedDependencyRequester);

        uint256 pendingUpgrade = legitDAO.pendingUpgradeForItself();
        Assert.notEqual(pendingUpgrade, 0, "Pending upgrade identifier should be non-zero");
    }

    /// #sender: account-0
    function testUpdateDependenciesThenCallFunction() public {
        // add the dependency requester:
        legitDAO.addDependencyRequester(dependencyRequester);

        // set addition outcome:
        dependencyRequester.setAdditionOutcome(1, contractAddress, true, true);

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
