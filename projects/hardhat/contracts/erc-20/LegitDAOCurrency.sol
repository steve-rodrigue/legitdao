// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract LegitDAOCurrency is ERC20, ERC20Burnable, ERC20Permit, ReentrancyGuard {

     // using Math for uint256 type
    using Math for uint256;

    uint256 public lastSnapshot;
    uint256 public snapshotDurationInSec = 60 * 5;
    uint256 public tokenToBNBExchangeRate = 1;
    uint256 public amountToBNBSwitches = 0;
    uint256 public amountToTokenSwitches = 0;
    uint256 public increment = 1;

    uint256[100] public snapshots;

    mapping(address => uint256) public depositsInBbn;
    mapping(address => uint256) public depositsInToken;

    event DepositToken(address indexed user, uint256 amount);
    event DepositBNB(address indexed user, uint256 amount);
    event WithdrawToken(address indexed user, uint256 amount);
    event WithdrawBNB(address indexed user, uint256 amount);
    event SwitchToBNB(address indexed user, uint256 amountOfBNB, uint256 amountOfToken, uint256 tokenToBNBExchangeRate);
    event SwitchToToken(address indexed user, uint256 amountOfToken, uint256 amountOfBNB, uint256 tokenToBNBExchangeRate);

    constructor()
        ERC20("LegitDAO Currency", "LEGIT-CUR")
        ERC20Permit("LegitDAO Currency")
    {
        // mint 10M to the contract creator:
        _mint(msg.sender, 10000000 * 10 ** decimals());

        // mint 90M to the contract
        _mint(address(this), 90000000 * 10 **decimals());

        // set the last snapshot:
        lastSnapshot = block.timestamp;
    }

    receive() external payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");

        // record the deposit:
        depositsInBbn[msg.sender] = msg.value;

        // emit the event:
        emit DepositToken(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function depositTokens(uint256 amount) public {
        require(amount > 0, "Must deposit a positive amount");

        // Transfer tokens from sender to this contract
        require(this.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the deposit balance
        depositsInToken[msg.sender] += amount;

        // emit the event:
        emit DepositToken(msg.sender, amount);
    }

    function withdrawBNB(uint256 amount) public {
        uint256 depositedAmount = depositsInBbn[msg.sender];
        require(depositedAmount <= 0, "No BNB deposited for that address");

        uint256 transferAmount = amount;
        if (amount < depositedAmount) {
            transferAmount = depositedAmount;
        }

        require(address(this).balance >= transferAmount, "Insufficient BNB balance in contract");

        depositsInBbn[msg.sender] = depositedAmount - transferAmount;
        payable(msg.sender).transfer(transferAmount);

        // emit the event:
        emit WithdrawBNB(msg.sender, transferAmount);
    }

    function withdrawToken(uint256 amount) public {
        uint256 depositedAmount = depositsInToken[msg.sender];
        require(depositedAmount <= 0, "No Token deposited for that address");

        uint256 transferAmount = amount;
        if (amount < depositedAmount) {
            transferAmount = depositedAmount;
        }

        depositsInToken[msg.sender] = depositedAmount - transferAmount;
        _transfer(address(this), msg.sender, transferAmount);

        // emit the event:
        emit WithdrawToken(msg.sender, transferAmount);
    }

    function switchToBNB(uint256 amount) public {

    }

    function switchToToken(uint256 amount) public {

    }
}