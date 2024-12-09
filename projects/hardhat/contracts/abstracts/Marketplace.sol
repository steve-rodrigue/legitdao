// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract Marketplace is  ReentrancyGuard {
    struct Offer {
        address user;
        uint256 price; // Price in Wei per token
        uint256 amount; // Amount of tokens to buy/sell
        bool isBuy; // True for buy offers, false for sell offers
    }

    mapping(uint256 => Offer) public offers; // Offer book (mapping from ID to Offer)
    uint256 public nextOfferId; // Incremental ID for offers

    mapping(address => uint256[]) public userOffers; // Track offers by user

    event BuyOfferCreated(uint256 offerId, address indexed user, uint256 price, uint256 amount);
    event SellOfferCreated(uint256 offerId, address indexed user, uint256 price, uint256 amount);
    event OfferWithdrawn(uint256 offerId, address indexed user);
    event TokensSold(address indexed seller, uint256 amountSold, uint256 totalReceived);

    constructor(){}

    // Create a buy offer
    function createBuyOfferInternal(uint256 price, uint256 amount) internal {
        require(price > 0 && amount > 0, "Invalid price or amount");

        uint256 offerId = nextOfferId++;
        offers[offerId] = Offer({
            user: msg.sender,
            price: price,
            amount: amount,
            isBuy: true
        });

        userOffers[msg.sender].push(offerId);
        emit BuyOfferCreated(offerId, msg.sender, price, amount);
    }

    // Create a sell offer
    function createSellOffer(uint256 price, uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(price > 0, "Invalid price");
        require(_balanceOfInternally(msg.sender) >= amount, "Insufficient token balance");
        require(_allowanceInternally(msg.sender, address(this)) >= amount, "Insufficient allowance");

        uint256 offerId = nextOfferId++;
        offers[offerId] = Offer({
            user: msg.sender,
            price: price,
            amount: amount,
            isBuy: false
        });

        userOffers[msg.sender].push(offerId);
        emit SellOfferCreated(offerId, msg.sender, price, amount);
    }

    // Withdraw an offer
    function withdrawOffer(uint256 offerId) external nonReentrant {
        Offer memory offer = offers[offerId];
        require(offer.amount > 0, "Offer already fulfilled or withdrawn");
        require(offer.user == msg.sender, "Not your offer");

        emit OfferWithdrawn(offerId, msg.sender);
        if (offer.isBuy) {
            uint256 refundAmount = offer.price * offer.amount;
            delete offers[offerId];
            transferAmount(msg.sender, refundAmount);
            return;
        }

        delete offers[offerId];
    }

    // Match sell order with highest buy offers
    function matchSellOrder(uint256 amountToSell, uint256 minPrice) external nonReentrant {
        require(amountToSell > 0, "Invalid amount");
        require(_balanceOfInternally(msg.sender) >= amountToSell, "Insufficient token balance");
        require(_allowanceInternally(msg.sender, address(this)) >= amountToSell, "Insufficient allowance");

        uint256 remainingTokens = amountToSell;
        uint256 totalReceived = 0;

        for (uint256 i = 0; i < nextOfferId && remainingTokens > 0; i++) {
            Offer storage offer = offers[i];

            if (offer.isBuy && offer.price >= minPrice && offer.amount > 0) {
                uint256 tokensToSell = offer.amount > remainingTokens ? remainingTokens : offer.amount;

                offer.amount -= tokensToSell;
                remainingTokens -= tokensToSell;
                totalReceived += tokensToSell * offer.price;

                _transferInternally(msg.sender, offer.user, tokensToSell);

                if (offer.amount == 0) {
                    delete offers[i];
                }
            }
        }

        require(totalReceived > 0, "No matching buy offers found");
        transferAmount(msg.sender, totalReceived);

        emit TokensSold(msg.sender, amountToSell - remainingTokens, totalReceived);
    }

    // Fetch offers by user
    function getUserOffers(address user) external view returns (uint256[] memory) {
        return userOffers[user];
    }

    // Fetch details of a specific offer
    function getOffer(uint256 offerId) external view returns (Offer memory) {
        return offers[offerId];
    }

    // Virtual function that can be overridden in derived contracts
    function transferAmount(address addr, uint256 amount) public virtual {
        require(amount > 0, "Amount must be greater than 0");
        payable(addr).transfer(amount);
    }

    function _balanceOfInternally(address addr) internal view virtual returns(uint256) {
        require(0 == 1, "_balanceOfInternally in Marketplace must be override");
        return 0;
    }

    function _allowanceInternally(address owner, address spender) internal view virtual returns(uint256) {
        require(0 == 1, "_allowanceInternally in Marketplace must be override");
        return 0;
    }

    function _transferInternally(address from, address to, uint256 amount) internal virtual {
        require(0 == 1, "_transfer in Marketplace must be override");
    }
}