// add the affiliate contract
// implement the pull system to distribute bnb from the minting to all token holders, send 15% of the bnb to the affiliates if a contract is set
// add the marketplace system to buy/sell tokens
// burn the tax of 0,50% (0,25% incoming, 0,25% outgoing)

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
    address[] private addressesOfTokenHolders;

    // represents the sell book
    mapping(address => MarketOrder) sellBook;

    // represents the current sell price
    uint256 currentSellPrice;

    // represents the buy book
    mapping(address => MarketOrder) buyBook;

    // represents the addresses of buy book
    address[] private addressOfBuyBook;

    // represents the current sell price
    uint256 currentBuyPrice;

    // represents the address payable mapping
    mapping(address => address payable) refundAddress;

    // initial tokens per 1 BNB
    uint256 public initialPricePerBNB;

    // amount to increment price per 1 BNB
    uint256 public priceIncrement; 

    // total BNB received by the contract
    uint256 public totalBNBReceived;

    constructor(
        uint256 _initialPricePerBNB,
        uint256 _priceIncrement
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
        currentSellPrice = initialPricePerBNB;
        currentBuyPrice = 0;
        priceIncrement = _priceIncrement;
        totalBNBReceived = 0;

    }

    receive() external payable nonReentrant {
        require(msg.value > 0, "Send BNB to receive tokens");

        // calculate the amount of tokens to assign:
        uint256 amountOfTokens = _calculateAmountOfTokens(msg.value);

        // ensure contract has enough tokens to distribute
        require(balanceOf(address(this)) >= amountOfTokens, "Not enough tokens in contract");

        // add the total BNB received:
        totalBNBReceived = totalBNBReceived.add(msg.value);
        
        // send the tokens to the sender:
       _transfer(address(this), msg.sender, amountOfTokens);

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
            balances[currentAddress] = ratio.mul(msg.value);
        }

        // add the address to the array:
        addressesOfTokenHolders.push(msg.sender);

        // BNB's are set to the contract address
    }

    // registers a sell order
    function registerSellOrder(uint256 amountOfTokens, uint256 requestedPricePerToken) external {
        // ensure the sender has enough tokens for sale:
        require(balanceOf(msg.sender) >= amountOfTokens, "Not enough tokens in contract");

        // if there is a previous sell order entry, cancel it:
        if (sellBook[msg.sender].amount > 0) {
            _cancelSellOrder();
        }

        // if there is tokens to buy lower than the price per token:
        uint256 remaining = _sellFromBuyBook(amountOfTokens, requestedPricePerToken);

        // if the cell price is lower than the current sell price, change it:
        if (requestedPricePerToken <= currentSellPrice) {
            currentSellPrice = requestedPricePerToken;
        }

        // register the sell order in the book:
        sellBook[msg.sender] = MarketOrder(remaining, requestedPricePerToken);

        // transfer the tokens to the contract:
        _transfer(msg.sender, address(this), remaining);
    }

    // sells tokens for bnb
    function _sellFromBuyBook(uint256 amountOfTokens, uint256 requestedPricePerToken) private returns(uint256) {
        if (currentBuyPrice > requestedPricePerToken) {
            return amountOfTokens;
        }

        uint256 remaining = 0;
        uint256 amountTransferInBNB = 0;
        for (uint256 i = 0; i < addressOfBuyBook.length; i++) {
            address addr = addressOfBuyBook[i];
            MarketOrder memory order = buyBook[addr];
            if (order.pricePerUnit > requestedPricePerToken) {
                continue;
            }

            // add the bnb value:
            amountTransferInBNB = amountTransferInBNB.add(amountOfTokens);

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

                // returns 0 as remaining:
                return 0;
            }
        }

         // transfer the amount:
        refundAddress[msg.sender].transfer(amountTransferInBNB);

        // return the remaining:
        return remaining;
    }

    // buy tokens with bnb
    function registerBuyOrder(uint256 requestedPrice, address payable refundTo) payable public {
        require(msg.value > 0, "Send BNB to register buy order");

        // if there is a previous buy order entry, cancel it:
        if (buyBook[msg.sender].amount > 0) {
           _cancelBuyOrder();
        }

        // find the amount of tokens:
        (uint256 amountOfNewTokens, uint256 amountRemaining) = _calculateAmountOfNewTokens(msg.value, requestedPrice);

        // if there is new tokens to assign:
        if (amountOfNewTokens > 0) {
            // transfer the new tokens:
            _transfer(address(this), msg.sender, amountOfNewTokens);
        }

        // if there is a remaining value:
        if (amountRemaining > 0) {
            // add the value to the book:
            buyBook[msg.sender] = MarketOrder(amountRemaining, requestedPrice);

            // add the refund address:
            refundAddress[msg.sender] = refundTo;

            // add the address to the buy book:
            addressOfBuyBook.push(msg.sender);

            // change the buy price if lower than the current one:
            if (currentBuyPrice <= requestedPrice) {
                currentBuyPrice = requestedPrice;
            }
        }

        // the BNB value is now transfered to the contract
    }

    function _cancelBuyOrder() public payable {
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

    function _cancelSellOrder() private {
        // fetch the amount:
        uint256 amount = sellBook[msg.sender].amount;

        // delete the entry from the book:
        delete sellBook[msg.sender];

        // transfer the tokens to the contract:
        _transfer(address(this), msg.sender, amount);
    }

    function cancelSellOrder() external {
       _cancelSellOrder();
    }

    // returns the balance of BNB on the contract:
    function getBalance() public view returns (uint256) {
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

    function _calculateAmountOfTokens(uint256 _value) private view returns (uint256) {
        // calculate the initial price:
        uint256 price = _priceOfNewTokens();

        // if the value is smaller than the price:
        if (_value <= price) {
            return _value.div(price);
        }

        // calculate the remaining bnb:
        uint256 remainingBNB = _value.sub(price);

        // calculate the remaining amount:
        uint256 amount = _calculateAmountOfTokens(remainingBNB);

        // return the amount + 1:
        return amount + 1;
    }

    function _calculateAmountOfNewTokens(uint256 _value, uint256 _requestedPrice) private view returns (uint256, uint256) {
        // calculate the initial price:
        uint256 price = _priceOfNewTokens();
        if (price > _requestedPrice) {
            return (0, _value);
        }

        // if the value is smaller than the price:
        if (_value <= price) {
            uint256 value = _value.div(price);
            return (value, _value % price);
        }

        // calculate the remaining bnb:
        uint256 remainingBNB = _value.sub(price);

        // calculate the remaining amount:
        (uint256 amount, uint256 remaining) = _calculateAmountOfNewTokens(remainingBNB, _requestedPrice);

        // return the amount + 1:
        return (amount + 1, remaining);
    }

    function _priceOfNewTokens() private view returns(uint256) {
        return totalBNBReceived.mul(priceIncrement);
    }
}
