// add the affiliate contract

// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract LegitDAOCurrency is ERC20, ERC20Burnable, ERC20Permit, ReentrancyGuard {

    struct MarketOrder {
        uint256 amount;
        uint256 pricePerUnit;
    }

     // using SafeMath for uint256 type
    using SafeMath for uint256;

    // mapping of users to ther balance:
   mapping(address => uint256) public balances;

   // addresses of token holders for iterating purposes
    address[] public addressesOfTokenHolders;

    // represents the sell book
    mapping(address => MarketOrder) public sellBook;

    // represents the current market sell price
    uint256 public currentMarketSellPrice;

    // represents the buy book
    mapping(address => MarketOrder) public buyBook;

    // represents the addresses of buy book
    address[] public addressOfBuyBook;

    // represents the current market buy price
    uint256 public currentMarketBuyPrice;

    // represents the address payable mapping
    mapping(address => address payable) public refundAddress;

    // initial tokens per 1 BNB
    uint256 public initialPricePerBNB;

    // amount to increment price per 1 BNB
    uint256 public priceIncrement; 

    // total BNB received by the contract
    uint256 public totalBNBReceived;

    // represents the buy tax percentage
    uint256 public buyTaxPercentage;

    // represents the sell tax percentage
    uint256 public sellTaxPercentage;

    // max price:
    uint256 private maxPrice = type(uint256).max;

    constructor(
        uint256 _initialPricePerBNB,
        uint256 _priceIncrement,
        uint256 _buyTaxPercentage,
        uint256 _sellTaxPercentage
    )
        ERC20("LegitDAO Currency", "LEGIT-CUR")
        ERC20Permit("LegitDAO Currency")
    {
        // mint 10M to the contract creator:
        _mint(msg.sender, 10000000 * 10 ** decimals());

        // mint 90M to the contract
        _mint(address(this), 9000000 * 10**decimals());

        // set properties:
        initialPricePerBNB = _initialPricePerBNB;
        currentMarketSellPrice = initialPricePerBNB;
        currentMarketBuyPrice = 0;
        priceIncrement = _priceIncrement;
        totalBNBReceived = 0;
        buyTaxPercentage = _buyTaxPercentage;
        sellTaxPercentage = _sellTaxPercentage;

    }

    receive() external payable nonReentrant {
        registerBuyOrder(maxPrice, payable(msg.sender));
    }

    // buy tokens with bnb
    function registerBuyOrder(uint256 requestedPrice, address payable refundTo) payable public {
        require(msg.value > 0, "Send BNB to register buy order");

        // if there is a previous buy order entry, cancel it:
        if (buyBook[msg.sender].amount > 0) {
           cancelBuyOrder();
        }

        // find the amount of tokens:
        (uint256 amountOfNewTokens, uint256 priceInBnb, uint256 amountRemaining) = _calculateAmountOfNewTokens(msg.value, requestedPrice);

        // execute the buy order:
        _executeBuy(amountOfNewTokens, priceInBnb, amountRemaining, requestedPrice, refundTo);

        // the BNB value is now transfered to the contract
    }

    // cancels a buy order
    function cancelBuyOrder() public payable {
        // fetch the amount:
        uint256 amount = buyBook[msg.sender].amount;

        // ensurce there is enough bnb in the contract:
        require(address(this).balance >= amount, "Insufficient BNB balance in contract");

        // delete the entry from the book:
        delete buyBook[msg.sender];

        // transfer the tokens to the contract:
        refundAddress[msg.sender].transfer(amount);

        // delete the entry from the refund address:
        delete refundAddress[msg.sender];
    }

    // registers a sell order
    function registerSellOrder(uint256 amountOfTokens, uint256 requestedPricePerToken) external {
        // ensure the sender has enough tokens for sale:
        require(balanceOf(msg.sender) >= amountOfTokens, "Not enough tokens in contract");

        // if there is a previous sell order entry, cancel it:
        if (sellBook[msg.sender].amount > 0) {
            cancelSellOrder();
        }

        // if there is tokens to buy lower than the price per token:
        (uint256 totalSellPriceInBnb, uint256 remaining) = _sellFromBuyBook(amountOfTokens, requestedPricePerToken);

        // calculate the ratio:
        uint256 ratio = calculatePerThousandage(totalSellPriceInBnb, buyTaxPercentage);
        
        // share the reward:
        uint256 rewardInBnbAmount = totalSellPriceInBnb.mul(ratio);
        _shareBnbReward(rewardInBnbAmount);

        // calculate the assign amount:

        // if the cell price is lower than the current sell price, change it:
        if (requestedPricePerToken <= currentMarketSellPrice) {
            currentMarketSellPrice = requestedPricePerToken;
        }

        // register the sell order in the book:
        sellBook[msg.sender] = MarketOrder(remaining, requestedPricePerToken);

        // transfer the tokens to the contract:
        _transfer(msg.sender, address(this), remaining);
    }

    function cancelSellOrder() public {
        // fetch the amount:
        uint256 amount = sellBook[msg.sender].amount;

        // delete the entry from the book:
        delete sellBook[msg.sender];

        // transfer the tokens to the contract:
        _transfer(address(this), msg.sender, amount);
    }

    // returns the balance of BNB on the contract:
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // returns the sender balance of BNB:
    function getSenderBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // withdraw an amount of bnb:
    function withdrawBNB(uint256 amount) external {
        // send the balance to the sener:
        uint256 balance = getSenderBalance();

        // ensure the amount is smaller than balance for that address:
        require(amount <= balance, "Amount is higher than balance");

        // transfer the balance:
        payable(msg.sender).transfer(balance);

        // update the balance:
        balances[msg.sender] = balance.sub(amount);
    }

    // sells tokens for bnb
    function _sellFromBuyBook(uint256 amountOfTokens, uint256 requestedPricePerToken) private returns(uint256, uint256) {
        if (currentMarketBuyPrice > requestedPricePerToken) {
            return (0, amountOfTokens);
        }

        uint256 remaining = 0;
        uint256 amountTransferInBNB = 0;
        for (uint256 i = 0; i < addressOfBuyBook.length; i++) {
            address addr = addressOfBuyBook[i];
            MarketOrder memory order = buyBook[addr];
            if (order.pricePerUnit > requestedPricePerToken) {
                continue;
            }

            // calculate the price in bnb:
            uint256 priceInBNB = amountOfTokens.mul(order.pricePerUnit);

            // add the bnb value:
            amountTransferInBNB = amountTransferInBNB.add(priceInBNB);

            // find the price:
            uint256 price = amountOfTokens.mul(order.pricePerUnit);

            // deduct the price from the remaining:
            remaining = remaining.sub(price);

            if (remaining <= 0) {
                // delete the entry from the book:
                delete addressOfBuyBook[i];

                // delete the address from the book order:
                delete buyBook[addr];

                // delete the address from the refund address:
                delete refundAddress[addr];

                // break:
                break;
            }
        }

        // return the remaining:
        return (amountTransferInBNB, remaining);
    }

    // executes a buy order from new tokens or book:
    function _executeBuy(uint256 amountOfNewTokens, uint256 priceInBnb, uint256 amountForBooks, uint256 requestedPrice, address payable refundTo) private  {
        // if there is new tokens to assign:
        if (amountOfNewTokens > 0) {
            // ensure contract has enough tokens to distribute
            require(balanceOf(address(this)) >= amountOfNewTokens, "Not enough tokens in contract");

            // calculate the reward in bnb:
            uint256 rewardInBnb = priceInBnb.mul(buyTaxPercentage);

            // share the reward:
            _shareBnbReward(rewardInBnb);

            // transfer the new tokens:
            _transfer(address(this), msg.sender, amountOfNewTokens);

            // add the total BNB received:
            totalBNBReceived = totalBNBReceived.add(amountOfNewTokens);

            // calculate the reward in token:
            uint256 rewardInToken = amountOfNewTokens.mul(sellTaxPercentage);

            // share the reward:
            _shareTokenReward(rewardInToken);
        }

        // execute the sell from the buy books:
        (uint256 totalSellPriceInBnb, uint256 remaining) = _sellFromBuyBook(amountForBooks, requestedPrice);

        // calculate the ratio:
        uint256 ratio = calculatePerThousandage(totalSellPriceInBnb, buyTaxPercentage);
        
        // share the reward:
        uint256 rewardInBnbAmount = totalSellPriceInBnb.mul(ratio);
        _shareBnbReward(rewardInBnbAmount);

        // if there is an amount from book value:
        if (remaining > 0) {
            // add the value to the book:
            buyBook[msg.sender] = MarketOrder(remaining, requestedPrice);

            // add the refund address:
            refundAddress[msg.sender] = refundTo;

            // add the address to the buy book:
            addressOfBuyBook.push(msg.sender);

            // change the buy price if lower than the current one:
            if (currentMarketBuyPrice <= requestedPrice) {
                currentMarketBuyPrice = requestedPrice;
            }
        }

        // add the address to the array:
        addressesOfTokenHolders.push(msg.sender);
    }

    function _shareBnbReward(uint256 amount) private {
        // calculate the share of bnb for each token holder:
       uint256 totalSupply = totalSupply();
       for (uint256 i = 0; i < addressesOfTokenHolders.length; i++) {
            // fetch the address:
            address currentAddress = addressesOfTokenHolders[i];

            // fetch the token balance for that address:
            uint256 currentBalance = balanceOf(currentAddress);

            // calculate the ratio to assign:
            uint256 ratio =  currentBalance.div(totalSupply);

            // update the bnb balance share:
            balances[currentAddress] = ratio.mul(amount);
        }
    }

    function _shareTokenReward(uint256 amount) private {
        // calculate the share of bnb for each token holder:
       uint256 totalSupply = totalSupply();
       for (uint256 i = 0; i < addressesOfTokenHolders.length; i++) {
            // fetch the address:
            address currentAddress = addressesOfTokenHolders[i];

            // fetch the token balance for that address:
            uint256 currentBalance = balanceOf(currentAddress);

            // calculate the ratio to assign:
            uint256 ratio =  currentBalance.div(totalSupply);

            // transfer the tokens:
            uint256 amountToShare = ratio.mul(amount);
            _transfer(address(this), currentAddress, amountToShare);
        }
    }

    function _calculateAmountOfNewTokens(uint256 _value, uint256 _requestedPrice) private view returns (uint256, uint256, uint256) {
        // calculate the initial price:
        uint256 price = _priceOfNewTokens();

        // if the price is higher than the requested price:
        if (price > _requestedPrice) {
            return (0, 0, _value);
        }

        // if the price is >= than the current market price:
        if (price >= currentMarketBuyPrice) {
            return (0, 0, _value);
        }

        // if the value is smaller than the price:
        if (_value <= price) {
            uint256 value = _value.div(price);
            return (value, price, _value % price);
        }

        // calculate the remaining bnb:
        uint256 remainingBNB = _value.sub(price);

        // calculate the remaining amount:
        (uint256 amount, uint256 subPrice, uint256 remaining) = _calculateAmountOfNewTokens(remainingBNB, _requestedPrice);

        // return the amount + 1:
        return (amount.add(1), subPrice.add(price), remaining);
    }

    function _priceOfNewTokens() private view returns(uint256) {
        return totalBNBReceived.mul(priceIncrement);
    }

    function calculatePerThousandage(uint256 amount, uint256 percentage) private pure returns (uint256) {
        return (amount * percentage) / 1000;
    }
}
