// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../interfaces/IFounder.sol";

/// @custom:security-contact stev.rodr@gmail.com
abstract contract Founder is IFounder, ERC20, ERC20Permit, Ownable, ReentrancyGuard {

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

    // erc-20 currency contract address:
    address public currencyAddress;

    constructor(
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
        ERC20Permit(name)
        Ownable(msg.sender)
    {}

    function setCurrencyAddress(address currAddr) public onlyOwner {
        require(currencyAddress == address(0), "Currency Address already set");
        require(currAddr != address(0), "Invalid address");
        require(IERC20(currAddr).totalSupply() != 0, "Provided contract is not a valid erc20");
        currencyAddress = currAddr;

        // emit:
        emit CurrencyAddressSet(currencyAddress);
    }

    function registerOfferWithDeposit(uint256 pricePerToken, uint256 amountOfTokens) public nonReentrant {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(pricePerToken > 0, "pricePerToken must be greater than zero");
        require(amountOfTokens > 0, "amountOfTokens must be greater than zero");

        // find the amount:
        (bool success, uint256 amount) = pricePerToken.tryMul(amountOfTokens);
        require(success, "pricePerToken * amountOfTokens overflows");
        
        depositCollateral(amount);
        registerOffer(amountOfTokens, pricePerToken);
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
        _transferCurrencyValueToUser(sendTo, transferAmount);

        // delete the offer:
        delete offers[offerAddress];
    }

    function depositCollateral(uint256 amount) public nonReentrant {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(amount > 0, "amount must be greater than zero");

        // transfer the units:
        _transferCurrencyValueToContract(amount);

        // record the collateral for that address:
        collateral[msg.sender] = amount;

        // emit the event:
        emit DepositCollateral(msg.sender, amount);

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
        _transferCurrencyValueToUser(sendTo, transferAmount);
    }

    function depositDividend(uint256 amount) public nonReentrant {
        require(amount > 0, "amount must be greater than zero(0)");

        // excecute the transfer to the contract:
        _transferCurrencyValueToContract(amount);

        // record the dividend:
        totalDividends += amount;

        // emit the event:
        emit DepositDividend(msg.sender, amount);

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
        
        // transfer the dividends in currency token:
        _transferCurrencyValueToUser(sendTo, transferAmount);

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

    function _transferCurrencyValueToUser(address sendTo, uint256 amount) private nonReentrant {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(amount > 0, "amount must be greater than zero(0");

        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom(address(this), sendTo, amount);
        require(success, "Token transfer failed");
    }

    function _transferCurrencyValueToContract(uint256 amount) private nonReentrant {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(amount > 0, "amount must be greater than zero(0");

        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom( msg.sender, address(this), amount);
        require(success, "Token transfer failed");
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