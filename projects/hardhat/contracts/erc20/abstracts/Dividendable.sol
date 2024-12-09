// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Dividendable is ERC20, Ownable, ReentrancyGuard {
    struct Currency {
        string name;
        string symbol;
        address addr;
    }

    mapping(string => Currency) public currencies; // Mapping from symbol to Currency
    string[] public currencySymbols; // List of currency symbols
    mapping(string => uint256) public totalWithdrawnDividends; // Track dividends for each currency
    mapping(string => uint256) public additionalContractDividends; // Additional dividends for each currency
    mapping(address => mapping(string => uint256)) public withdrawnDividends; // Withdrawn dividends per account and currency

    string public primaryCurrencySymbol;
    address public primaryCurrencyAddress;

    event CurrencyAdded(string symbol, string name, address indexed addr);
    event WithdrawDividends(string symbol, address recipient, uint256 amount);
    event AdditionalDividendsAdded(string symbol, uint256 amount);
    event PrimaryCurrencySet(string symbol, string name, address indexed addr);
    event DividendsTransfered(address from, address to, uint256 dividends, string symbol);

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {}

    // Add a new currency
    function addCurrency(address currAddr) public onlyOwner {
        return _addCurrencyFromAddress(currAddr);
    }

    // Set primary currency
    function setPrimaryCurrency(address currAddr) public onlyOwner {
        require(primaryCurrencyAddress == address(0), "Primary currency already set");
        require(currAddr != address(0), "Invalid address");

        ERC20 token = ERC20(currAddr);
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint256 totalSupply = token.totalSupply();

        primaryCurrencyAddress = currAddr;
        primaryCurrencySymbol = tokenSymbol;

        emit PrimaryCurrencySet(tokenSymbol, tokenName, currAddr);

        return _addCurrency(currAddr, tokenName, tokenSymbol, totalSupply);
    }

    // Get the list of currencies
    function getCurrencies() public view returns (Currency[] memory) {
        Currency[] memory result = new Currency[](currencySymbols.length);
        for (uint256 i = 0; i < currencySymbols.length; i++) {
            result[i] = currencies[currencySymbols[i]];
        }
        return result;
    }

    // Get available dividends for an account and currency
    function getAvailableDividends(string memory symbol, address account) public view returns (uint256) {
        require(currencies[symbol].addr != address(0), "Currency not found");

        uint256 totalDivs = totalDividends(symbol) + totalWithdrawnDividends[symbol] + additionalContractDividends[symbol];
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = balanceOf(account);
        uint256 owedDividends = (totalDivs * accountBalance) / totalSupply;

        if (owedDividends <= 0) {
            return 0;
        }

        return owedDividends - withdrawnDividends[account][symbol];
    }

    // Get total dividends available for a currency
    function totalDividendsAvailable(string memory symbol) public view returns (uint256) {
        require(currencies[symbol].addr != address(0), "Currency not found");

        uint256 totalDivs = totalDividends(symbol) + additionalContractDividends[symbol];
        if (totalDivs <= 0) {
            return 0;
        }

        return totalDivs - totalWithdrawnDividends[symbol];
    }

    // Get total dividends for a currency
    function totalDividends(string memory symbol) public view returns (uint256) {
        require(currencies[symbol].addr != address(0), "Currency not found");

        IERC20 token = IERC20(currencies[symbol].addr);
        return token.balanceOf(address(this));
    }

    // Withdraw dividends for a specific currency
    function withdrawDividends(string memory symbol, uint256 amount) public nonReentrant {
        require(currencies[symbol].addr != address(0), "Currency not found");
        _withdrawToDividends(msg.sender, symbol, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient funds");

        string memory symbol;
        for (uint256 i = 0; i < currencySymbols.length; i++) {
            // Fetch the symbol
            symbol = currencySymbols[i];

            // Proportionally withdraw dividends:
            uint256 withdrawnDivs = 0;
            uint256 senderDividends = getAvailableDividends(symbol, msg.sender);
            if (senderDividends > 0) {
                withdrawnDivs = (senderDividends * amount) / senderBalance;

                // withdraw the dividends:
                _withdrawToDividends(recipient, symbol, withdrawnDivs);
            }

            // Emit event:
            emit DividendsTransfered(msg.sender, recipient, withdrawnDivs, symbol);
        }
        
        // Transfer the remaining amount:
        return super.transfer(recipient, amount);
    }

    // Internal function to withdraw dividends
    function _withdrawToDividends(address to, string memory symbol, uint256 amount) internal {
        require(amount > 0, "Amount cannot be 0");

        uint256 available = getAvailableDividends(symbol, to);
        require(available > 0, "No dividends available");

        if (available < amount) {
            amount = available;
        }

        withdrawnDividends[to][symbol] += amount;
        totalWithdrawnDividends[symbol] += amount;

        _transferCurrencyFromContract(to, symbol, amount);

        emit WithdrawDividends(symbol, to, amount);
    }

    // Internal function to transfer currency from the contract
    function _transferCurrencyFromContract(address to, string memory symbol, uint256 amount) internal {
        require(currencies[symbol].addr != address(0), "Currency not found");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(currencies[symbol].addr);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        bool success = token.transfer(to, amount);
        require(success, "Token transfer failed");
    }

    // Internal function to add additional dividends for a currency
    function _addToAdditionalContractDividends(string memory symbol, uint256 amount) internal {
        require(currencies[symbol].addr != address(0), "Currency not found");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(currencies[symbol].addr);
        require(token.balanceOf(address(this)) >= additionalContractDividends[symbol] + amount, "Insufficient contract balance");

        additionalContractDividends[symbol] += amount;

        emit AdditionalDividendsAdded(symbol, amount);
    }

    function _addCurrencyFromAddress(address currAddr) private {
        require(currAddr != address(0), "Invalid address");

        ERC20 token = ERC20(currAddr);
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint256 totalSupply = token.totalSupply();

        return _addCurrency(currAddr, tokenName, tokenSymbol, totalSupply);
    }
    
    function _addCurrency(address currAddr, string memory tokenName, string memory tokenSymbol, uint256 totalSupply) private {
        require(bytes(tokenSymbol).length > 0, "Invalid token symbol");
        require(bytes(tokenName).length > 0, "Invalid token name");
        require(currencies[tokenSymbol].addr == address(0), "Currency already added");
         require(totalSupply > 0, "Provided Currency ERC20 contract should not have a total supply of 0");

        currencies[tokenSymbol] = Currency({
            name: tokenName,
            symbol: tokenSymbol,
            addr: currAddr
        });

        currencySymbols.push(tokenSymbol);

        emit CurrencyAdded(tokenSymbol, tokenName, currAddr);
    }
}