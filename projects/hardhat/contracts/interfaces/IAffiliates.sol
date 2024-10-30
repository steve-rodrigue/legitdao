// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAffiliates {
    // set contracts:
    function setCurrencyAddress(address currAddr) external;
    function setFounderAddress(address fdrAddress) external;

    // token-based payment system:
    function receivePayment(address child, uint256 amount) external;
    function claimPayment(address sendTo, uint256 amount) external;

    // referral system:
    function register(address child) external;
    function getParent(address child) external view returns(address);
    function getChildren() external view returns(address[] memory);

    // marketplace:
    function registerOffer(uint256 tokenId, uint256 price) external;
    function withdrawOffer(uint256 tokenId) external;
    function getOfferForToken(uint256 tokenId) external view returns(uint256);
    function acceptOffer(address sendTo, uint256 tokenId) external; 
    function getMyTokenOffers() external view returns(uint256[] memory);

    // events:
    event CurrencyAddressSet(address indexed currencyAddress);
    event FounderAddressSet(address indexed currencyAddress);
    event PaymentReceived(address indexed user, uint256 shareAmount, uint256 totalAmount);
    event PaymentClaimed(address indexed user, uint256 amount);
    event RegisterReferral(address indexed owner, address indexed referral);
    event RegisterOffer(address indexed user, uint256 tokenId, uint256 amount);
    event WithdrawOffer(address indexed user, uint256 tokenId);
    event AcceptOffer(address indexed user, uint256 tokenId, uint256 price);
}