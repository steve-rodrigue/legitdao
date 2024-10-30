// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

interface IFounder {
    // set contracts:
    function setCurrencyAddress(address currAddr) external;

    // dividends:
    function depositDividend(uint256 amount) external;
    function withdrawDividend(address sendTo, uint256 amount) external;
    function dividendAmount() external view returns (uint256);

    // marketplace:
    function registerOfferWithDeposit(uint256 pricePerToken, uint256 amountOfTokens) external;
    function registerOffer(uint256 amount, uint256 pricePerToken) external;
    function withdrawOffer() external;
    function acceptOffer(address sendTo, address offerAddress) external;
    function depositCollateral(uint256 amount) external;
    function withdrawCollateral(address sendTo, uint256 amount) external;

    // events:
    event CurrencyAddressSet(address indexed currencyAddress);
    event DepositDividend(address indexed user, uint256 amount);
    event WithdrawnDividend(address indexed user, uint256 amount);
    event DepositCollateral(address indexed user, uint256 amount);
    event WithdrawnCollateral(address indexed user, uint256 amount);
}