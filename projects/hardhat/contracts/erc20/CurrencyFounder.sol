// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IDividendable.sol";


/// @custom:security-contact stev.rodr@gmail.com
contract CurrencyFounder is IDividendable, ERC20, ERC20Permit, ReentrancyGuard {
    uint256 private constant SCALE = 1e18;
    uint256 public totalDividends = 0;
    mapping(address => uint256) private accountsDividendsWithdrawn;

    constructor()
        ERC20("LegitDAO Currency Founder", "LEGIT-CURF")
        ERC20Permit("LegitDAO Currency Founder")
    {
        address firstTwentyFive = address(0xb2BB6301216bCe25128123EE22A23847fa80Cde7);
        address secondTwentyFive = address(0x20343F2CeBf5895c5d5707B25d0c3f526816F4dc);
        address firstFourHundredSeventyFive = address(0x5a9eD1f68865A4719a4F3928EdB2c1BbbA8655c4);
        address secondFourHundredSeventyFive = address(0x13B7fD960C3c105c0a80f05a2430783345A7c8dC);

        // mint 5M:
        _mint(firstTwentyFive, 2500000 * 10 ** decimals());

        // mint 5M:
        _mint(secondTwentyFive, 2500000 * 10 ** decimals());

        // mint 47.5M:
        _mint(firstFourHundredSeventyFive, 47500000 * 10 ** decimals());

        // mint 47.5M:
        _mint(secondFourHundredSeventyFive, 47500000 * 10 ** decimals());
    }

    receive() external payable nonReentrant {
        require(msg.value > 0, "Send BNB to deposit payment");

        // Record the dividend
        totalDividends += msg.value;

        // Emit the event
        emit PaymentReceivedInContract(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function getDividendAmount(address addr) public view returns (uint256) {
        uint256 balance = balanceOf(addr); 
        uint256 totalSupply = totalSupply();
        return _calculateAmountBasedOnToken(balance, totalSupply, totalDividends);
    }

    function withdrawDividend(address sendTo, uint256 amount) public nonReentrant {
        return _withdrawDividendToAddress(msg.sender, sendTo, amount);
    }

    function _withdrawDividendToAddress(address holder, address sendTo, uint256 amount) private {
        require(amount > 0, "Amount must be greater than zero");
        uint256 dividend = getDividendAmount(holder);
        require(dividend > 0, "No dividend for that address");

        uint256 transferAmount = amount;
        if (transferAmount > dividend) {
            transferAmount = dividend;
        }
        
        // transfer the dividends in native value:
        _transferNativeValue(sendTo, transferAmount);

        // record the dividends paid:
        accountsDividendsWithdrawn[msg.sender] += transferAmount;

        // emit the event:
        emit DividendWithdrawn(msg.sender, transferAmount);
    }

    function _transferNativeValue(address sendTo, uint256 amount) private {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function _calculateAmountBasedOnToken(uint256 tokenAmount, uint256 tokenTotalAmount, uint256 value) private pure returns(uint256) {
        if (tokenTotalAmount <= 0) {
            return 0;
        }

        // Calculate the scaled ratio to prevent truncation
        uint256 scaled = tokenAmount * SCALE;

        uint256 scaledRatio = scaled / tokenTotalAmount;
        
        // Calculate the dividend by applying the ratio to the total dividends
        uint256 retValue = value * scaledRatio;

        uint256 retValueDownScaled = retValue / SCALE;

        return retValueDownScaled;
    }

    // method overloads:
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        uint256 balance = balanceOf(msg.sender);
        uint256 withdrawnInNative = _calculateAmountBasedOnToken(value, balance, accountsDividendsWithdrawn[msg.sender]);

        accountsDividendsWithdrawn[to] += withdrawnInNative;
        accountsDividendsWithdrawn[msg.sender] -= withdrawnInNative;

        return super.transfer(to, value);
    }
}