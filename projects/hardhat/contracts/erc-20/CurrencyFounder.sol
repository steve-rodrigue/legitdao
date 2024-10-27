// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract CurrencyFounder is ERC20, ERC20Permit, ReentrancyGuard {

     // using Math for uint256 type
    using Math for uint256;

    uint256 private constant SCALE = 1e18;
    
    uint256 public totalDividendsInBNB = 0;
    mapping(address => uint256) private accountsDividendsInBNBWithdrawn;

    // events:
    event DividendDepositInBNB(address indexed user, uint256 amount);
    event DividendInBNBWithdrawn(address indexed user, uint256 amount);

    constructor()
        ERC20("LegitDAO Currency Founder", "LEGIT-CURF")
        ERC20Permit("LegitDAO Currency Founder")
    {
        address firstTwentyFive = address(0xb2BB6301216bCe25128123EE22A23847fa80Cde7);
        address secondTwentyFive = address(0x20343F2CeBf5895c5d5707B25d0c3f526816F4dc);
        address firstFourHundredSeventyFive = address(0x5a9eD1f68865A4719a4F3928EdB2c1BbbA8655c4);
        address secondFourHundredSeventyFive = msg.sender;

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
        require(msg.value > 0, "Send BNB to register buy order");

        // record the dividend:
        totalDividendsInBNB += msg.value;

        // emit the event:
        emit DividendDepositInBNB(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function withdrawBNBDividend(address sendTo, uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(totalDividendsInBNB > 0, "Contract has no dividend to pay");

        uint256 dividend = dividendAmount();
        require(dividend > 0, "No dividend for that address");

        uint256 transferAmount = amount;
        if (transferAmount > dividend) {
            transferAmount = dividend;
        }
        
        // transfer the dividends in bnb:
        (bool success, ) = payable(sendTo).call{value: transferAmount}("");
        require(success, "Transfer failed");

        // record the dividends paid:
        accountsDividendsInBNBWithdrawn[msg.sender] += transferAmount;

        // emit the event:
        emit DividendInBNBWithdrawn(msg.sender, transferAmount);
    }

    function dividendAmount() public view returns (uint256) {
        uint256 balance = balanceOf(msg.sender); 
        uint256 totalSupply = totalSupply();
        return calculateAmountBasedOnToken(balance, totalSupply, totalDividendsInBNB);
    }

    function calculateAmountBasedOnToken(uint256 tokenAmount, uint256 tokenTotalAmount, uint256 value) private pure returns(uint256) {
        require(tokenTotalAmount > 0, "tokenTotalAmount cannot be zero");

        // Calculate the scaled ratio to prevent truncation
        (bool balanceSuccess,  uint256 scaled) = tokenAmount.tryMul(SCALE);
        require(balanceSuccess, "tokenAmount * SCALE overflows");

        (bool success,  uint256 scaledRatio) = scaled.tryDiv(tokenTotalAmount);
        require(success, "scaled / tokenTotalAmount overflows");
        
        // Calculate the dividend by applying the ratio to the total dividends
        (bool retValueSuccess, uint256 retValue) = value.tryMul(scaledRatio);
        require(retValueSuccess, "value * scaledRatio overflows");

        (bool downScaleSuccess, uint256 retValueDownScaled) = retValue.tryDiv(SCALE);
        require(downScaleSuccess, "retValue / SCALE overflows");

        return retValueDownScaled;
    }

    // method overloads:
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        uint256 balance = balanceOf(msg.sender);
        uint256 withdrawnInBNB = calculateAmountBasedOnToken(value, balance, accountsDividendsInBNBWithdrawn[msg.sender]);

        accountsDividendsInBNBWithdrawn[to] += withdrawnInBNB;
        accountsDividendsInBNBWithdrawn[msg.sender] -= withdrawnInBNB;

        return super.transfer(to, value);
    }
}