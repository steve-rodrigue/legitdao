// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../erc-20/LegitDAOCurrency.sol";

import "hardhat/console.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    uint256 initialPricePerBNB;
    uint256 priceIncrement;
    uint256 buyTaxPercentage;
    uint256 sellTaxPercentage;

    LegitDAOCurrency instance;

    /// #sender: account-0
    /// #value: 1000000000000
    function beforeAll() public {
        instance = new LegitDAOCurrency();

        Assert.equal(uint(1), uint(1), "1 should be equal to 1");
    }

    // test public properties after initialization
    function testPublicPropertiesSuccess() public {
       //Assert.equal(instance.initialPricePerBNB(), initialPricePerBNB, "Initial price per BNB is invalid");
       //Assert.equal(instance.priceIncrement(), priceIncrement, "Price increment is invalid");
       //Assert.equal(instance.buyTaxPercentage(), buyTaxPercentage, "Buy tax percentage is invalid");
       //Assert.equal(instance.sellTaxPercentage(), sellTaxPercentage, "Sell tax percentage is invalid");
    }

    /// #sender: account-0
    /// #value: 1000000000000
    /*function testRegisterBuyOrder() payable public {
       
        uint256 requestedPrice = 20;
        (bool success, ) = address(instance).call{value: msg.value}(
            abi.encodeWithSignature("registerBuyOrder(uint256,address)", requestedPrice, TestsAccounts.getAccount(0))
        );

        Assert.ok(success, "RegisterBuyOrder failed");
        console.log("total supply: ", instance.totalSupply());
    }*/

    /// #sender: account-0
    /// #value: 1000000000000
    /*function testReceive() payable public {
        (bool success, ) = address(instance).call{value: msg.value}("");
        Assert.ok(success, "Receive failed");

        console.log("total supply: ", instance.totalSupply());
    }*/
}
    