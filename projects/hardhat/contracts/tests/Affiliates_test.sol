// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../erc-721/Affiliates.sol";

contract MyCurrency is ERC20 {
    constructor() ERC20("My Name", "TIK") {
        _mint(msg.sender, 10 ** decimals());
    }
}

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    Affiliates instance;
    IERC20 currencyAddress;
    IERC20 secondCurrencyAddress;

    function beforeAll() public {
        instance = new Affiliates();
        currencyAddress = new MyCurrency();
        secondCurrencyAddress = new MyCurrency();

        uint256 sum = 0;
        for (uint256 i = 0; i < 7; i++) {
            uint256 level = instance.levelRatios(i);
            sum += level;
        }

        console.log(sum);
    }

    function testSetCurrencyAddress_Success() public {
        // initial address is 0x0:
        Assert.ok(instance.currencyAddress() == address(0), "Currency address should be 0x0");

        // set the contract:
        instance.setCurrencyAddress(address(currencyAddress));

        // verify the address:
        Assert.ok(instance.currencyAddress() == address(currencyAddress), "Currency address is invalid");

        // second time should fail:
        try instance.setCurrencyAddress(address(secondCurrencyAddress)) {
            Assert.ok(false, "Should fail to set the Currency address twice");
        } catch {

        }
    }

    function testSetCurrencyAddress_withInvalidAddressType_Fails() public {
        try instance.setCurrencyAddress(address(TestsAccounts.getAccount(0))) {
            Assert.ok(false, "Should fail to set the currency address to a non ERC-20 address");
        } catch {
            
        }
    }

    function testSetCurrencyAddress_withAddressZero_Fails() public {
        try instance.setCurrencyAddress(address(0)) {
            Assert.ok(false, "Should fail to set the Currency address to 0x0");
        } catch {
            
        }
    }
}
    