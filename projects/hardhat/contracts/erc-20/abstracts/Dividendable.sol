// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IDividendable.sol";

/// @custom:security-contact stev.rodr@gmail.com
abstract contract Dividendable is IDividendable, ERC20, ERC20Permit, ReentrancyGuard {

    struct Offer {
        uint256 pricePerToken;
        uint256 amountOfToken;
    }

     // using Math for uint256 type
    using Math for uint256;

    uint256 private constant SCALE = 1e18;
    
    uint256 public totalDividends = 0;
    mapping(address => Offer) public offers;
    mapping(address => uint256) private accountsDividendsWithdrawn;
    mapping(address => uint256) public collateral;

    function registerOfferWithDeposit(uint256 pricePerToken) public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");
        
        depositCollateral();
        registerOffer(msg.value, pricePerToken);
    }

    function registerOffer(uint256 amount, uint256 pricePerToken) public {
        Offer memory offerIns = offers[msg.sender];
        if (offerIns.amountOfToken > 0) {
            withdrawOffer();
        }

        offerIns.amountOfToken = amount;
        offerIns.pricePerToken = pricePerToken;
    }

    function withdrawOffer() public {
        delete offers[msg.sender];
    }

    function acceptOffer(address sendTo, address offerAddress) public {
        // fetch the offer:
        Offer memory offerIns = offers[offerAddress];
        require(offerIns.pricePerToken > 0, "No offer for address");

        // calculate the dividend to pay:
        uint256 balance = balanceOf(msg.sender);
        uint256 dividendToPay = _calculateAmountBasedOnToken(offerIns.amountOfToken, balance, dividendAmount());

        // pay the dividend:
        withdrawDividend(sendTo, dividendToPay);

        // transfer the tokens:
        _transfer(msg.sender, offerAddress, offerIns.amountOfToken);

        // calculate the amount of payment for the tokens:
        uint256 transferAmount = offerIns.amountOfToken * offerIns.pricePerToken;

        // execute the transfer:
        _transferNativeValue(sendTo, transferAmount);

        // delete the offer:
        delete offers[offerAddress];
    }

    function depositCollateral() public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");

        // record the collateral for that address:
        collateral[msg.sender] = msg.value;

        // emit the event:
        emit DepositCollateral(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function withdrawCollateral(address sendTo, uint256 amount) public {
        uint256 deposited = collateral[msg.sender];
        require(deposited > 0, "No collateral for that address");

        // record the collateral for that address:
        uint256 transferAmount = amount;
        if (amount > deposited) {
            transferAmount = deposited;
        }

        collateral[msg.sender] -= transferAmount;

        // emit the event:
        emit WithdrawnCollateral(msg.sender, transferAmount);

        // execute the transfer:
        _transferNativeValue(sendTo, transferAmount);
    }

    function depositDividend() public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");

        // record the dividend:
        totalDividends += msg.value;

        // emit the event:
        emit DepositDividend(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function withdrawDividend(address sendTo, uint256 amount) public nonReentrant {
        return withdrawDividendToAddress(msg.sender, sendTo, amount);
    }

    function dividendAmount() public view returns (uint256) {
        return _dividendAmount(msg.sender);
    }

     function withdrawDividendToAddress(address holder, address sendTo, uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(totalDividends > 0, "Contract has no dividend to pay");

        uint256 dividend = _dividendAmount(holder);
        require(dividend > 0, "No dividend for that address");

        uint256 transferAmount = amount;
        if (transferAmount > dividend) {
            transferAmount = dividend;
        }
        
        // transfer the dividends in bnb:
        _transferNativeValue(sendTo, transferAmount);

        // record the dividends paid:
        accountsDividendsWithdrawn[msg.sender] += transferAmount;

        // emit the event:
        emit WithdrawnDividend(msg.sender, transferAmount);
    }

    function _dividendAmount(address holder) private view returns (uint256) {
        uint256 balance = balanceOf(holder); 
        uint256 totalSupply = totalSupply();
        return _calculateAmountBasedOnToken(balance, totalSupply, totalDividends);
    }

    function _transferNativeValue(address sendTo, uint256 amount) private nonReentrant {
        (bool success, ) = payable(sendTo).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function _calculateAmountBasedOnToken(uint256 tokenAmount, uint256 tokenTotalAmount, uint256 value) private pure returns(uint256) {
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
        uint256 withdrawnInBNB = _calculateAmountBasedOnToken(value, balance, accountsDividendsWithdrawn[msg.sender]);

        accountsDividendsWithdrawn[to] += withdrawnInBNB;
        accountsDividendsWithdrawn[msg.sender] -= withdrawnInBNB;

        return super.transfer(to, value);
    }
}