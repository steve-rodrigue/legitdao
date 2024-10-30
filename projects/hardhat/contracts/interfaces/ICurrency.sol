// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICurrency {
    // dividends:
    function depositDividend() external payable;
    function withdrawDividend(address sendTo, uint256 amount) external;
    function dividendAmount() external view returns (uint256);

    // marketplace:
    function registerOfferWithDeposit(uint256 pricePerToken) external payable;
    function registerOffer(uint256 amount, uint256 pricePerToken) external;
    function withdrawOffer() external;
    function acceptOffer(address sendTo, address offerAddress) external;
    function depositCollateral() external payable;
    function withdrawCollateral(address sendTo, uint256 amount) external;

    // events:
    event TokensPurchased(address indexed buyer, uint256 bnbSpent, uint256 tokensReceived, uint256 newTokenPrice);
    event FounderAddressSet(address indexed currencyAddress);
    event DepositDividend(address indexed user, uint256 amount);
    event WithdrawnDividend(address indexed user, uint256 amount);
    event DepositCollateral(address indexed user, uint256 amount);
    event WithdrawnCollateral(address indexed user, uint256 amount);
}