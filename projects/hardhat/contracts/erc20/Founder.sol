// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Founder is ERC20, Ownable, ReentrancyGuard {
    uint256 public totalWithdrawnDividends = 0;

    mapping(address => uint256) public withdrawnDividends;

    event CurrencyAddressSet(address indexed currencyAddress);
    event WithdrawDividends(address recipient, uint256 amount);
    event TransferExecuted(address from, address to, uint256 amount, uint256 dividends);

    // erc-20 currency address:
    address public currencyAddress = address(0);

    constructor(
        address[] memory holders
    )
        ERC20("LegitDAO Founder", "LEGITF") 
         Ownable(msg.sender)
    {
        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], 10_000_000 * 10 ** decimals());
        }
    }

    function setCurrencyAddress(address currAddr) public onlyOwner {
        require(currencyAddress == address(0), "Currency Address already set");
        require(currAddr != address(0), "Invalid address");

        uint256 totalSupply = IERC20(currAddr).totalSupply();
        require(totalSupply != 0, "Provided Currency ERC20 contract should not have a total supply of 0");
        
        currencyAddress = currAddr;

        // emit:
        emit CurrencyAddressSet(currencyAddress);
    }

    function getAvailableDividends(address account) public view returns (uint256) {
        uint256 totalDivs = totalDividends() + totalWithdrawnDividends;
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = balanceOf(account);
        uint256 owedDividends = (totalDivs * accountBalance) / totalSupply;
        if (owedDividends <= 0) {
            return 0;
        }

        return owedDividends - withdrawnDividends[account];
    }

    function totalDividendsAvailable() public view returns (uint256) {
        uint256 totalDivs = totalDividends();
        if (totalDivs <= 0) {
            return 0;
        }

        return totalDivs - totalWithdrawnDividends;
    }

    function totalDividends() public view returns(uint256) {
        require(currencyAddress != address(0), "Currency Address not set");
        IERC20 token = IERC20(currencyAddress);
        return token.balanceOf(address(this));
    }

    function withdrawDividends(uint256 amount) public nonReentrant {
        _withdrawToDividends(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient funds");

        // Proportionally withdraw dividends:
        uint256 withdrawnDivs = 0;
        uint256 senderDividends = getAvailableDividends(msg.sender);
        if (senderDividends > 0) {
            withdrawnDivs = (senderDividends * amount) / senderBalance;

            // withdraw the dividends:
            _withdrawToDividends(recipient, withdrawnDivs);
        }

        // Emit event:
        emit TransferExecuted(msg.sender, recipient, amount, withdrawnDivs);
        
        // Transfer the remaining amount:
        return super.transfer(recipient, amount);
    }

    function _withdrawToDividends(address to, uint256 amount) public {
        require(amount > 0, "Amount cannot be 0");

        uint256 toTransfer = amount;
        uint256 available = getAvailableDividends(to);
        require(available > 0, "No dividends available");

        if (available < toTransfer) {
            toTransfer = available;
        }
        
        withdrawnDividends[to] += toTransfer;
        totalWithdrawnDividends += toTransfer;
        _transferCurrencyFromContract(to, toTransfer);

        // emit:
        emit WithdrawDividends(to, toTransfer);
    }

    function _transferCurrencyFromContract(address to, uint256 amount) private {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(amount > 0, "amount must be greater than 0");

        IERC20 token = IERC20(currencyAddress);
        bool approveSuccess = token.approve(address(this), amount);
        require(approveSuccess, "Token approval failed");

        bool success = token.transferFrom(address(this), to, amount);
        require(success, "Token transfer failed");
    }
}