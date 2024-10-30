// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../interfaces/ICurrency.sol";

/// @custom:security-contact stev.rodr@gmail.com
contract Currency is ICurrency, ERC20, ERC20Permit, Ownable, ReentrancyGuard {

    uint256 public taxRate; // 25 for 0,25%
    uint256 public basisPoints; // 10000 if we put 25 in taxRate, to return 0,25%

    struct Offer {
        uint256 pricePerToken;
        uint256 amountOfToken;
    }

    // price per token in wei
    uint256 public tokenPrice;  

    // rate of price increase per BNB received
    uint256 public priceIncreaseRate; 

    // track total BNB received
    uint256 public totalBNBReceived; 

    uint256 public lastPriceInBNB;

    uint256 private constant SCALE = 1e18;
    
    uint256 public totalDividends = 0;
    mapping(address => Offer) public offers;
    mapping(address => uint256) private accountsDividendsWithdrawn;
    mapping(address => uint256) public collateral;

    // founder address:
    address founderAddress;

    constructor(
        uint256 _initialPrice, 
        uint256 _priceIncreaseRate,
        uint256 _taxRate,
        uint256 _basisPoints
    )
        ERC20("LegitDAO Currency", "LEGIT-CURR")
        ERC20Permit("LegitDAO Currency")
        Ownable(msg.sender)
    {

        // mint 100M to contract:
        _mint(address(this), 100000000 * 10 ** decimals());

        // set properties:
        tokenPrice = _initialPrice;
        priceIncreaseRate = _priceIncreaseRate;
        taxRate = _taxRate;
        basisPoints = _basisPoints;
    }

    receive() payable nonReentrant external {
        require(msg.value > 0, "No BNB sent");

        uint256 bnbRemaining = msg.value;
        uint256 totalTokensToSend = 0;

        while (bnbRemaining > 0) {
            // Calculate the amount of tokens for the current price tier
            uint256 tokensAtCurrentPrice = getNewTokenPrice(); // Tokens per 1 BNB at current price
            uint256 costForThisTier = tokensAtCurrentPrice * tokenPrice;

            if (bnbRemaining >= costForThisTier) {
                // full BNB amount at current price tier
                totalTokensToSend += tokensAtCurrentPrice;
                bnbRemaining -= costForThisTier;
                totalBNBReceived += costForThisTier;

                // increase the price for the next BNB increment
                tokenPrice += priceIncreaseRate;
                continue;
            }

            // calculate partial tokens if remaining BNB is less than the current tier cost
            uint256 partialTokens = (bnbRemaining * 1 ether) / tokenPrice;
            totalTokensToSend += partialTokens;
            totalBNBReceived += bnbRemaining;
            bnbRemaining = 0;
        }
        
        // send the tokens to the sender
        _transfer(address(this), msg.sender, totalTokensToSend);

        // update the total BNB received
        totalBNBReceived += msg.value;

        // increase the dividends:
        totalDividends += msg.value;

        // increase the token price based on the defined rate
        tokenPrice += priceIncreaseRate;

        // emit:
        emit TokensPurchased(msg.sender, msg.value, totalTokensToSend, tokenPrice);

        // BNB is awarded to the contract
    }

    function getNewTokenPrice() public view returns(uint256) {
        return 1 ether / tokenPrice;
    }

    function setFounderAddress(address currAddr) public onlyOwner {
        require(founderAddress == address(0), "Founder Address already set");
        require(currAddr != address(0), "Invalid address");
        require(IERC20(currAddr).totalSupply() != 0, "Provided contract is not a valid erc20");
        founderAddress = currAddr;

        // send 25M units to the founder's contract:
        super._transfer(address(this), founderAddress, 25000000 * 10 ** decimals());

        // emit:
        emit FounderAddressSet(founderAddress);
    }

    function registerOfferWithDeposit(uint256 pricePerToken) public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");
        
        depositCollateral();
        registerOffer(msg.value, pricePerToken);
    }

    function registerOffer(uint256 amount, uint256 pricePerToken) public {
        Offer memory offerIns = offers[msg.sender];
        if (offerIns.amountOfToken > 0) {
            withdrawOffer();
        }

        require(pricePerToken >  getNewTokenPrice(), "the price per token is higher than the minting price");

        offerIns.amountOfToken = amount;
        offerIns.pricePerToken = pricePerToken;
    }

    function withdrawOffer() public {
        delete offers[msg.sender];
    }

    function acceptOffer(address sendTo, address offerAddress) public {
        // fetch the offer:
        Offer memory offerIns = offers[offerAddress];
        require(offerIns.pricePerToken > 0, "No offer for address");
        require(offerIns.pricePerToken >  getNewTokenPrice(), "the offer is priced higher than the current mining price");

        // calculate the dividend to pay:
        uint256 balance = balanceOf(msg.sender);
        uint256 dividendToPay = _calculateAmountBasedOnToken(offerIns.amountOfToken, balance, dividendAmount());

        // pay the dividend:
        withdrawDividend(sendTo, dividendToPay);

        // transfer the tokens:
        transfer(offerAddress, offerIns.amountOfToken);

        // calculate the amount of payment for the tokens:
        uint256 transferAmount = offerIns.amountOfToken * offerIns.pricePerToken;

        // execute the transfer:
        _transferNativeValue(sendTo, transferAmount);

        // delete the offer:
        delete offers[offerAddress];
    }

    function depositCollateral() public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");

        // record the collateral for that address:
        collateral[msg.sender] = msg.value;

        // emit the event:
        emit DepositCollateral(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function withdrawCollateral(address sendTo, uint256 amount) public {
        uint256 deposited = collateral[msg.sender];
        require(deposited > 0, "No collateral for that address");

        // record the collateral for that address:
        uint256 transferAmount = amount;
        if (amount > deposited) {
            transferAmount = deposited;
        }

        collateral[msg.sender] -= transferAmount;

        // emit the event:
        emit WithdrawnCollateral(msg.sender, transferAmount);

        // execute the transfer:
        _transferNativeValue(sendTo, transferAmount);
    }

    function depositDividend() public payable nonReentrant {
        require(msg.value > 0, "Send BNB to register buy order");

        // record the dividend:
        totalDividends += msg.value;

        // emit the event:
        emit DepositDividend(msg.sender, msg.value);

        // the BNB value is now transfered to the contract
    }

    function withdrawDividend(address sendTo, uint256 amount) public nonReentrant {
        return withdrawDividendToAddress(msg.sender, sendTo, amount);
    }

    function dividendAmount() public view returns (uint256) {
        return _dividendAmount(msg.sender);
    }

     function withdrawDividendToAddress(address holder, address sendTo, uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(totalDividends > 0, "Contract has no dividend to pay");

        uint256 dividend = _dividendAmount(holder);
        require(dividend > 0, "No dividend for that address");

        uint256 transferAmount = amount;
        if (transferAmount > dividend) {
            transferAmount = dividend;
        }
        
        // transfer the dividends in bnb:
        _transferNativeValue(sendTo, transferAmount);

        // record the dividends paid:
        accountsDividendsWithdrawn[msg.sender] += transferAmount;

        // emit the event:
        emit WithdrawnDividend(msg.sender, transferAmount);
    }

    function _dividendAmount(address holder) private view returns (uint256) {
        uint256 balance = balanceOf(holder); 
        uint256 totalSupply = totalSupply();
        return _calculateAmountBasedOnToken(balance, totalSupply, totalDividends);
    }

    function _transferNativeValue(address sendTo, uint256 amount) private nonReentrant {
        (bool success, ) = payable(sendTo).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function _calculateAmountBasedOnToken(uint256 tokenAmount, uint256 tokenTotalAmount, uint256 value) private pure returns(uint256) {
        require(tokenTotalAmount > 0, "tokenTotalAmount cannot be zero");

        // Calculate the scaled ratio to prevent truncation
        uint256 scaled = tokenAmount * SCALE;
        uint256 scaledRatio = scaled / tokenTotalAmount;
        
        // Calculate the dividend by applying the ratio to the total dividends
        uint256 retValue = value * scaledRatio;
        return retValue / SCALE;
    }

    // method overloads:
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        // Calculate 0.25% tax on both sender and receiver
        uint256 taxAmount = (value * taxRate) / basisPoints;
        uint256 transferAmount = value - (2 * taxAmount); // Deduct tax from the transfer amount

        // Send the tax to the founder's conttract:
        super._transfer(msg.sender, founderAddress, taxAmount);    // Tax from sender
        super._transfer(to, founderAddress, taxAmount); // Tax from receiver

        uint256 balance = balanceOf(msg.sender);
        uint256 withdrawnInBNB = _calculateAmountBasedOnToken(transferAmount, balance, accountsDividendsWithdrawn[msg.sender]);

        accountsDividendsWithdrawn[to] += withdrawnInBNB;
        accountsDividendsWithdrawn[msg.sender] -= withdrawnInBNB;

        return super.transfer(to, transferAmount);
    }
}