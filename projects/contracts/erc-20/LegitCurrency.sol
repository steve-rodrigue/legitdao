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

     // using SafeMath for uint256 type
    using SafeMath for uint256;

    // mapping of users to ther balance:
   mapping(address => uint256) public balances;

   // array to keep track of addresses (for iterating purposes)
    address[] public userAddresses;

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
       for (uint256 i = 0; i < userAddresses.length; i++) {
            // fetch the address:
            address currentAddress = userAddresses[i];

            // fetch the balance for that address:
            uint256 currentBalance = balances[currentAddress];

            // calculate the ratio to assign:
            uint256 ratio =  currentBalance.div(totalSupply);

            // update the balance:
            balances[currentAddress] = ratio.mul(msg.value);
        }

        // BNB's are set to the contract address
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
        uint256 price = totalBNBReceived.mul(priceIncrement);

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
}