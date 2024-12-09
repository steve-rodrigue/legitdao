// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Dividendable is ERC20, Ownable, ReentrancyGuard {
    uint256 public totalWithdrawnDividends = 0;
    uint256 public additionalContractDividends = 0;
    mapping(address => uint256) public withdrawnDividends;

    address public currencyAddress = address(0);

    event CurrencyAddressSet(address indexed currencyAddress);
    event WithdrawDividends(address recipient, uint256 amount);
    event TransferExecuted(address from, address to, uint256 amount, uint256 dividends);
    event AdditionalDividendsAdded(uint256 amount);

    constructor(
        string memory name, 
        string memory symbol
    ) 
        ERC20(name, symbol)  
        Ownable(msg.sender) 
    {

    }

    function setCurrencyAddress(address currAddr) public onlyOwner {
        require(currencyAddress == address(0), "Currency Address already set");
        require(currAddr != address(0), "Invalid address");

        uint256 totalSupply = IERC20(currAddr).totalSupply();
        require(totalSupply != 0, "Provided Currency ERC20 contract should not have a total supply of 0");
        
        currencyAddress = currAddr;

        emit CurrencyAddressSet(currencyAddress);
    }

    function getAvailableDividends(address account) public view returns (uint256) {
        uint256 totalDivs = totalDividends() + totalWithdrawnDividends + additionalContractDividends;
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = balanceOf(account);
        uint256 owedDividends = (totalDivs * accountBalance) / totalSupply;
        if (owedDividends <= 0) {
            return 0;
        }

        return owedDividends - withdrawnDividends[account];
    }

    function totalDividendsAvailable() public view returns (uint256) {
        uint256 totalDivs = totalDividends() + additionalContractDividends;
        if (totalDivs <= 0) {
            return 0;
        }

        return totalDivs - totalWithdrawnDividends;
    }

    function totalDividends() public view returns (uint256) {
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

        uint256 withdrawnDivs = 0;
        uint256 senderDividends = getAvailableDividends(msg.sender);
        if (senderDividends > 0) {
            withdrawnDivs = (senderDividends * amount) / senderBalance;
            _withdrawToDividends(recipient, withdrawnDivs);
        }

        emit TransferExecuted(msg.sender, recipient, amount, withdrawnDivs);
        return super.transfer(recipient, amount);
    }

    function _withdrawToDividends(address to, uint256 amount) internal {
        require(amount > 0, "Amount cannot be 0");

        uint256 available = getAvailableDividends(to);
        require(available > 0, "No dividends available");
        if (available < amount) {
            amount = available;
        }

        withdrawnDividends[to] += amount;
        totalWithdrawnDividends += amount;

        _transferCurrencyFromContract(to, amount);

        emit WithdrawDividends(to, amount);
    }

    function _transferCurrencyFromContract(address to, uint256 amount) internal {
        require(currencyAddress != address(0), "Currency Address not set");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(currencyAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        bool success = token.transfer(to, amount);
        require(success, "Token transfer failed");
    }

    function _addToAdditionalContractDividends(uint256 amount) internal {
        require(currencyAddress != address(0), "Currency Address not set");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(currencyAddress);
        require(token.balanceOf(address(this)) >= additionalContractDividends + amount, "Insufficient contract balance");

        additionalContractDividends += amount;

        emit AdditionalDividendsAdded(amount);
    }
}