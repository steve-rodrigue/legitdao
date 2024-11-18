import { expect } from "chai";
import { ethers } from "hardhat";
import { ethers as ethersUtils } from "ethers";
import { Affiliates,  ERC20Mock} from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";


describe("Affiliates Contract", function () {
  let affiliates: Affiliates;
  let currency: ERC20Mock;
  let currencyWithZeroTotalSupply: ERC20Mock;
  let founder: ERC20Mock;
  let deployer: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let child: SignerWithAddress;
  let parent: SignerWithAddress;
  let nonParent: SignerWithAddress;
  const levelRatios = [BigInt(5333), BigInt(2666), BigInt(999), BigInt(334), BigInt(334), BigInt(167), BigInt(167)];
  const DESCALE = BigInt(10000);

  beforeEach(async () => {
    [deployer, nonOwner, child, parent, nonParent] = await ethers.getSigners();

    // Deploy the Affiliates contract
    const Affiliates = await ethers.getContractFactory("Affiliates");
    affiliates = await Affiliates.connect(deployer).deploy();

    // Deploy the Founder contract
    const Founder = await ethers.getContractFactory("ERC20Mock");
    founder = await Founder.connect(deployer).deploy("Founder Mock Token", "FMTK", ethersUtils.parseEther("1000000"));

    // Deploy a mock currency token contract
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    currency = await ERC20Mock.deploy("Mock Token", "MTK", ethersUtils.parseEther("1000000"));

    // Deploy a mock ERC20 token contract with 0 total supply:
    const ERC20MockWithZeroTotalSupply = await ethers.getContractFactory("ERC20Mock");
    currencyWithZeroTotalSupply = await ERC20MockWithZeroTotalSupply.deploy("No Supply Mock Token", "NSMTK", ethersUtils.parseEther("0"));

    // send some currency to the non-owner:
    let balance = await currency.connect(deployer).balanceOf(deployer.address);
    await currency.connect(deployer).approve(deployer.address, ethersUtils.parseEther("500"));
    await currency.connect(deployer).transferFrom(deployer, nonOwner, ethersUtils.parseEther("500"));
  });

  it("should set the currency address successfully if called by the deployer", async () => {
    // Set the currency address
    await expect(affiliates.connect(deployer).setCurrencyAddress(currency.target))
      .to.emit(affiliates, "CurrencyAddressSet")
      .withArgs(currency.target);

    // Verify the currency address
    const currencyAddress = await affiliates.currencyAddress();
    expect(currencyAddress).to.equal(currency.target);
  });

  it("should revert if currency address is already set", async () => {
    // Set the currency address for the first time
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Attempt to set the currency address again
    await expect(affiliates.connect(deployer).setCurrencyAddress(currency.target))
      .to.be.revertedWith("Currency Address already set");
  });

  it("should revert if called by a non-deployer", async () => {
    await expect(affiliates.connect(nonOwner).setCurrencyAddress(currency.target))
    .to.be.revertedWithCustomError(affiliates, "OwnableUnauthorizedAccount");
  });

  it("should revert if the provided address is zero", async () => {
    await expect(affiliates.connect(deployer).setCurrencyAddress("0x0000000000000000000000000000000000000000"))
      .to.be.revertedWith("Invalid address");
  });

  it("should revert if the provided contract is not a valid ERC20", async () => {
    const nonERC20Contract = ethers.Wallet.createRandom().address; // A random address
    await expect(affiliates.connect(deployer).setCurrencyAddress(nonERC20Contract))
      .to.be.reverted;
  });

  it("should revert if the currency address has 0 total supply", async () => {
    await expect(affiliates.connect(deployer).setCurrencyAddress(currencyWithZeroTotalSupply.target))
      .to.be.revertedWith("Provided Currency ERC20 contract should not have a total supply of 0");
  });

  it("should emit the CurrencyAddressSet event with the correct address", async () => {
    await expect(affiliates.connect(deployer).setCurrencyAddress(currency))
      .to.emit(affiliates, "CurrencyAddressSet")
      .withArgs(currency);
  });

  it("should successfully set the founder address when called by the deployer", async function () {
    await expect(affiliates.connect(deployer).setFounderAddress(founder))
        .to.emit(affiliates, "FounderAddressSet")
        .withArgs(founder);

    const founderAddress = await affiliates.founderAddress();
    expect(founderAddress).to.equal(founder);
  });

  it("should revert if the founder address is already set", async function () {
    await affiliates.connect(deployer).setFounderAddress(founder);

    await expect(
        affiliates.connect(deployer).setFounderAddress(founder)
    ).to.be.revertedWith("Founder Address already set");
  });

  it("should revert if a non-deployer tries to set the founder address", async function () {
    await expect(
        affiliates.connect(nonOwner).setFounderAddress(founder)
    ).to.be.revertedWithCustomError(affiliates, "OwnableUnauthorizedAccount");
  });

  it("should revert if the provided address is the zero address", async function () {
    await expect(
        affiliates.connect(deployer).setFounderAddress("0x0000000000000000000000000000000000000000")
    ).to.be.revertedWith("Invalid address");
  });

  it("should revert if the provided address is not a valid ERC20 contract", async function () {
    const invalidAddress = nonOwner.address; // Non-contract address

    await expect(
        affiliates.connect(deployer).setFounderAddress(invalidAddress)
    ).to.be.reverted; // Revert due to invalid ERC20 totalSupply() call
  });

  it("should revert if the provided ERC20 contract has a total supply of 0", async function () {
    await expect(
        affiliates.connect(deployer).setFounderAddress(currencyWithZeroTotalSupply.target)
    ).to.be.revertedWith("Provided Founder ERC20 contract should not have a total supply of 0");
  });

  it("should distribute payments correctly to the parent", async function () {
    const amount = BigInt(10);

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(affiliates.connect(deployer).sendPayment(child.address, amount))
        .to.emit(affiliates, "PaymentReceived")
        .withArgs(parent.address, amount * (levelRatios[0]) / (DESCALE), amount);
  });

  it("should revert if the amount is zero", async function () {
    const amount = ethersUtils.parseEther("0");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(
        affiliates.connect(deployer).sendPayment(child.address, amount)
    ).to.be.revertedWith("amount must be greater than zero");
  });

  it("should revert if the currency address is not set", async function () {
    const Affiliates = await ethers.getContractFactory("Affiliates");
    const newAffiliates = await Affiliates.deploy();

    const amount = ethersUtils.parseEther("10");

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(
        newAffiliates.connect(deployer).sendPayment(child.address, amount)
    ).to.be.revertedWith("currency contract address has not been set");
  });

  it("should forward remaining payment to the founder if there is no parent", async function () {
    const orphanChild = nonParent.address;
    const amount = ethersUtils.parseEther("10");

     // Set the currency address
     await affiliates.connect(deployer).setCurrencyAddress(currency.target);

     // Set the founder address
     await affiliates.connect(deployer).setFounderAddress(founder.target);
 
     // Register a parent-child relationship
     await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(affiliates.connect(deployer).sendPayment(orphanChild, amount))
        .to.emit(affiliates, "FounderPaymentReceived")
        .withArgs(amount);
  });

  it("should revert if founder address not set", async function () {
    const orphanChild = nonParent.address;
    const amount = ethersUtils.parseEther("10");

     // Set the currency address
     await affiliates.connect(deployer).setCurrencyAddress(currency.target);
 
     // Register a parent-child relationship
     await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(affiliates.connect(deployer).sendPayment(orphanChild, amount))
        .to.revertedWith("Founder Address not set");
  });

  it("should fail if user allowance is too small", async function () {
    const sendTo = ethers.Wallet.createRandom(); // A random address

    const amount = BigInt(10);
    const level = 0;

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, 1);

    await expect(affiliates.connect(deployer).sendPayment(child.address, amount))
    .to.be.revertedWith("Allowance cannot be smaller than amount");
  });

  it("should allow a user to claim payment if they have a sufficient balance", async function () {
    const sendTo = ethers.Wallet.createRandom(); // A random address

    const amount = BigInt(10);
    const level = 0;

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(affiliates.connect(deployer).sendPayment(child.address, amount))
        .to.emit(affiliates, "PaymentReceived")
        .withArgs(parent.address, amount * (levelRatios[level]) / (DESCALE), amount);

    // Get parent payment:
    const parentPayment = await affiliates.connect(parent).paymentBook(parent);
    const expectedPayment = (amount * levelRatios[0]) / DESCALE;
    expect(parentPayment).to.equal(expectedPayment);

    // Parent claims a portion of the payment
    const claimAmount = ethersUtils.parseEther("5");
    await affiliates.connect(parent).claimPayment(sendTo.address, parentPayment);

    // Verify recipient received the tokens
    const recipientBalance = await currency.balanceOf(sendTo.address);
    expect(recipientBalance).to.equal(parentPayment);

    // Verify user's paymentBook balance is updated
    const remainingBalance = await affiliates.paymentBook(parent.address);
    expect(remainingBalance).to.equal(0);
  });

  it("should revert if claim amount is zero", async function () {
    const sendTo = ethers.Wallet.createRandom(); // A random address

    await expect(affiliates.connect(deployer).claimPayment(sendTo.address, 0))
      .to.be.revertedWith("amount must be greater than zero");
  });

  it("should revert if user has zero balance in paymentBook", async function () {
    const sendTo = ethers.Wallet.createRandom();
    const claimAmount = ethersUtils.parseEther("1");
    await expect(affiliates.connect(parent).claimPayment(sendTo.address, claimAmount))
      .to.be.revertedWith("sender has 0 balance");
  });

  it("should cap the claim amount to the user's available balance", async function () {
    const sendTo = ethers.Wallet.createRandom(); // A random address

    const amount = BigInt(10);
    const level = 0;
    const expectedBalance = amount * (levelRatios[level]) / (DESCALE);

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(parent).register(child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);

    await expect(affiliates.connect(deployer).sendPayment(child.address, amount))
        .to.emit(affiliates, "PaymentReceived")
        .withArgs(parent.address, expectedBalance, amount);

    // User tries to claim more than their balance
    const claimAmount = expectedBalance + ethersUtils.parseEther("15");
    await affiliates.connect(parent).claimPayment(sendTo.address, claimAmount);

    // Verify recipient received only the user's balance
    const recipientBalance = await currency.balanceOf(sendTo.address);
    expect(recipientBalance).to.equal(expectedBalance);

    // Verify user's paymentBook balance is now zero
    const remainingBalance = await affiliates.paymentBook(sendTo.address);
    expect(remainingBalance).to.equal(0);
  });

  it("should successfully register a new offer, then successfully accept the offer", async function () {
    const offerPrice = ethersUtils.parseEther("10");
    const sendToTokenRecipient = ethers.Wallet.createRandom();

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(deployer).register(child.address);

    // Fetch the token if from our child:
    const tokenId = await affiliates.connect(deployer).getTokenId(deployer.address, child.address);

    // initial balances:
    const initialNewOwnerBalance = await currency.balanceOf(nonOwner);
    const initialOriginalOwnerBalance = await currency.balanceOf(deployer)

    // Approve the transfer contract to spend user's tokens
    await currency.connect(nonOwner).approve(affiliates.target, offerPrice);

    await expect(affiliates.connect(nonOwner).registerOffer(tokenId, offerPrice))
      .to.emit(affiliates, "RegisterOffer")
      .withArgs(nonOwner.address, tokenId, offerPrice);

    // make sure the offer is registered
    const newOwnerOffers = await affiliates.connect(nonOwner).getMyTokenOffers();
    expect(newOwnerOffers.length).to.eq(1);

    const registeredPrice = await affiliates.offersByAddressTokenIdPrice(nonOwner.address, tokenId);
    expect(registeredPrice).to.equal(offerPrice);

    const offerer = await affiliates.tokenIdOfferer(tokenId);
    expect(offerer).to.equal(nonOwner.address);

    await expect(affiliates.connect(deployer).acceptOffer(sendToTokenRecipient, tokenId))
        .to.emit(affiliates, "AcceptOffer")
        .withArgs(nonOwner.address, sendToTokenRecipient.address, tokenId, offerPrice);

    // make sure the the token is transfered
    const transferedTokenId = await affiliates.connect(deployer).getTokenId(nonOwner.address, child.address);
    expect(transferedTokenId).to.eq(tokenId);

    // make sure the new owner is the real owner:
    const newOnerAddress = await affiliates.connect(deployer).ownerOf(tokenId);
    expect(newOnerAddress).to.eq(nonOwner.address);

    // make sure the offer has been deleted:
    const newOwnerFinalOffers = await affiliates.connect(nonOwner).getMyTokenOffers();
    expect(newOwnerFinalOffers.length).to.eq(0);

    // make sur the currency is transfered:
    const finalNewOwnerBalance = await currency.connect(nonOwner).balanceOf(nonOwner);
    expect(finalNewOwnerBalance).to.eq(initialNewOwnerBalance - offerPrice);

    const finalOriginalOwnerBalance = await currency.connect(deployer).balanceOf(deployer);
    expect(finalOriginalOwnerBalance).to.eq(initialOriginalOwnerBalance + offerPrice);

  });

  it("should should revert if calling acceptOffer without a registered offer on that token", async function () {
    const offerPrice = ethersUtils.parseEther("10");
    const sendToTokenRecipient = ethers.Wallet.createRandom();

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(deployer).register(child.address);

    // Fetch the token if from our child:
    const tokenId = await affiliates.connect(deployer).getTokenId(deployer.address, child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(nonOwner).approve(affiliates.target, offerPrice);

    await expect(affiliates.connect(deployer).acceptOffer(sendToTokenRecipient, tokenId))
        .to.revertedWith("no offer for that token");

  });

  it("should revert when registering an offer on a token that does NOT exists", async function () {
    const offerPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(deployer).register(child.address);

    // Fetch the token if from our child:
    const tokenId = await affiliates.connect(deployer).getTokenId(deployer.address, child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(nonOwner).approve(affiliates.target, offerPrice);

    await expect(affiliates.connect(nonOwner).registerOffer(tokenId+BigInt(1), offerPrice))
      .to.revertedWith("the token does not exists");
  });

  it("should revert when registering an offer on his own token", async function () {
    const offerPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(deployer).register(child.address);

    // Fetch the token if from our child:
    const tokenId = await affiliates.connect(deployer).getTokenId(deployer.address, child.address);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, offerPrice);

    await expect(affiliates.connect(deployer).registerOffer(tokenId, offerPrice))
      .to.revertedWith("current token holder can NOT register an offer on his own token");
  });

  it("should revert when registering an offer if allowance is too low", async function () {
    const offerPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Register a parent-child relationship
    await affiliates.connect(deployer).register(child.address);

    // Fetch the token if from our child:
    const tokenId = await affiliates.connect(deployer).getTokenId(deployer.address, child.address);

    await expect(affiliates.connect(nonOwner).registerOffer(tokenId, offerPrice))
      .to.revertedWith("Allowance cannot be smaller than amount");
  });

  it("should revert if currency address is not set", async function () {
    const tokenId = 1;
    const offerPrice = ethersUtils.parseEther("10");

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, offerPrice);

    await expect(
      affiliates.connect(deployer).registerOffer(tokenId, offerPrice)
    ).to.be.revertedWith("currency contract address has not been set");
  });

  it("should revert if price is zero", async function () {
    const tokenId = 1;

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, 1);

    await expect(
        affiliates.connect(deployer).registerOffer(tokenId, 0)
    ).to.be.revertedWith("price must be greater than zero");
  });

  it("should successfully replace an existing offer with a higher price", async function () {
    const tokenId = 1;
    const initialPrice = ethersUtils.parseEther("10");
    const newPrice = ethersUtils.parseEther("15");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, initialPrice);

    // Register the initial offer
    await affiliates.connect(deployer).registerOffer(tokenId, initialPrice);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, newPrice);

    // Replace the offer with a higher price
    await expect((await affiliates.connect(deployer).registerOffer(tokenId, newPrice)).wait())
      .to.emit(affiliates, "RegisterOffer")
      .withArgs(deployer.address, tokenId, newPrice);

    const registeredPrice = await affiliates.offersByAddressTokenIdPrice(deployer.address, tokenId);
    expect(registeredPrice).to.equal(newPrice);
  });

  it("should revert if replacing an offer with a lower or equal price", async function () {
    const tokenId = 1;
    const initialPrice = ethersUtils.parseEther("10");
    const lowerPrice = ethersUtils.parseEther("5");
    const equalPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, initialPrice);

    // Register the initial offer
    const txResponse = await affiliates.connect(deployer).registerOffer(tokenId, initialPrice);
    await txResponse.wait();

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, lowerPrice);

    // Attempt to replace the offer with a lower price
    await expect(
      affiliates.connect(deployer).registerOffer(tokenId, lowerPrice)
    ).to.be.revertedWith("current offer registered higher than your price");

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, equalPrice);

    // Attempt to replace the offer with an equal price
    await expect(
      affiliates.connect(deployer).registerOffer(tokenId, equalPrice)
    ).to.be.revertedWith("current offer registered higher than your price");
  });

  it("should withdraw the previous offer when replacing it", async function () {
    const tokenId = 1;
    const initialPrice = ethersUtils.parseEther("10");
    const newPrice = ethersUtils.parseEther("15");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, initialPrice);

    // Get initial balance:
    const initialBalance = await currency.balanceOf(deployer.address);

    // Register the initial offer
    await affiliates.connect(deployer).registerOffer(tokenId, initialPrice);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, newPrice);

    // Replace the offer with a higher price
    await affiliates.connect(deployer).registerOffer(tokenId, newPrice);

    // Ensure the previous offer is withdrawn
    const previousOffer = await affiliates.offersByAddressTokenIdPrice(deployer.address, tokenId);
    expect(previousOffer).to.equal(newPrice);

    // Ensure the token was transferred back
    const userBalance = await currency.balanceOf(deployer.address);
    expect(userBalance).to.equal(initialBalance - newPrice);
  });

  it("should revert if currencyAddress is not set", async () => {
    const tokenId = 1;
    const initialPrice = ethersUtils.parseEther("10");
    const newPrice = ethersUtils.parseEther("15");

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, initialPrice);

    // Get initial balance:
    const initialBalance = await currency.balanceOf(deployer.address);

    await expect(
        affiliates.connect(deployer).registerOffer(tokenId, initialPrice)
    ).to.be.revertedWith("currency contract address has not been set");
  });

  it("should revert if no offer is registered for the token by the sender", async () => {
    const invalidTokenId = 999;
    const initialPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, initialPrice);

    await expect(
        affiliates.connect(deployer).withdrawOffer(invalidTokenId)
    ).to.be.revertedWith("no offer registered from the provided address");
  });

  it("should return 0 if no offer exists for the token", async () => {
    const nonExistentTokenId = 999;
    const offerPrice = await affiliates.getOfferForToken(nonExistentTokenId);
    expect(offerPrice).to.equal(0);
  });

  it("should return the correct price if an offer is registered for the token", async () => {
    const tokenId = 1;
    const tokenId2 = 2;
    const offerPrice = ethersUtils.parseEther("10");
    const offerPrice2 = ethersUtils.parseEther("15");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(nonOwner).approve(affiliates.target, offerPrice);

    // Register the initial offer
    await affiliates.connect(nonOwner).registerOffer(tokenId, offerPrice);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(nonOwner).approve(affiliates.target, offerPrice2);

    // Register the initial offer
    await affiliates.connect(nonOwner).registerOffer(tokenId2, offerPrice2);

    const priceForToken1 = await affiliates.getOfferForToken(tokenId);
    expect(priceForToken1).to.equal(offerPrice);

    const priceForToken2 = await affiliates.getOfferForToken(tokenId2);
    expect(priceForToken2).to.equal(offerPrice2);
  });

it("should revert if the caller is not the owner of the token", async () => {
    const tokenId = 1;
    const offerPrice = ethersUtils.parseEther("10");

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, offerPrice);

    // Register the initial offer
    await affiliates.connect(deployer).registerOffer(tokenId, offerPrice);

    await expect(
        affiliates.connect(parent).acceptOffer(parent.address, tokenId)
    ).to.be.revertedWith("current address is not the owner of that tokenId");
  });

  it("should distribute payments across 7 levels of referral hierarchy", async function () {
    const amount = ethersUtils.parseEther("100");
  
    // Create 7 users for the referral hierarchy
    const [level1, level2, level3, level4, level5, level6, level7, level8] = await ethers.getSigners();

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);
  
    // Register the referral hierarchy
    await affiliates.connect(level1).register(level2.address);
    await affiliates.connect(level2).register(level3.address);
    await affiliates.connect(level3).register(level4.address);
    await affiliates.connect(level4).register(level5.address);
    await affiliates.connect(level5).register(level6.address);
    await affiliates.connect(level6).register(level7.address);
    await affiliates.connect(level7).register(level8.address);
  
    // Approve and send payment to the 7th level
    await currency.connect(deployer).approve(affiliates.target, amount);
    await expect(affiliates.connect(deployer).sendPayment(level8.address, amount))
        .to.not.emit(affiliates, "FounderPaymentReceived");
    
    const expectedPayments = [
        (amount * levelRatios[0]) / DESCALE,
        (amount * levelRatios[1]) / DESCALE,
        (amount * levelRatios[2]) / DESCALE,
        (amount * levelRatios[3]) / DESCALE,
        (amount * levelRatios[4]) / DESCALE,
        (amount * levelRatios[5]) / DESCALE,
        (amount * levelRatios[6]) / DESCALE,
    ];
  
    const paymentLevel1 = await affiliates.paymentBook(level1.address);
    expect(paymentLevel1).to.equal(expectedPayments[6]);
  
    const paymentLevel2 = await affiliates.paymentBook(level2.address);
    expect(paymentLevel2).to.equal(expectedPayments[5]);
  
    const paymentLevel3 = await affiliates.paymentBook(level3.address);
    expect(paymentLevel3).to.equal(expectedPayments[4]);
  
    const paymentLevel4 = await affiliates.paymentBook(level4.address);
    expect(paymentLevel4).to.equal(expectedPayments[3]);
  
    const paymentLevel5 = await affiliates.paymentBook(level5.address);
    expect(paymentLevel5).to.equal(expectedPayments[2]);
  
    const paymentLevel6 = await affiliates.paymentBook(level6.address);
    expect(paymentLevel6).to.equal(expectedPayments[1]);
  
    const paymentLevel7 = await affiliates.paymentBook(level7.address);
    expect(paymentLevel7).to.equal(expectedPayments[0]);
  
    // Verify no extra payments are left unallocated
    const totalPaid = expectedPayments.reduce((acc, curr) => acc + curr, BigInt(0));
    const founderPayment = await affiliates.paymentBook(founder.target);
    expect(founderPayment).to.equal(amount - totalPaid);
  });

  it("should distribute payments across 7 levels of referral hierarchy and founder payment", async function () {
    const amount = ethersUtils.parseEther("100");
  
    // Create 7 users for the referral hierarchy
    const [level1, level2, level3, level4, level5, level6, level7, level8] = await ethers.getSigners();

    // Set the currency address
    await affiliates.connect(deployer).setCurrencyAddress(currency.target);

    // Set the founder address
    await affiliates.connect(deployer).setFounderAddress(founder.target);

    // Approve the transfer contract to spend user's tokens
    await currency.connect(deployer).approve(affiliates.target, amount);
  
    // Register the referral hierarchy
    await affiliates.connect(level1).register(level2.address);
    await affiliates.connect(level2).register(level3.address);
    await affiliates.connect(level3).register(level4.address);
    await affiliates.connect(level4).register(level5.address);
    await affiliates.connect(level5).register(level6.address);
    await affiliates.connect(level6).register(level7.address);
    await affiliates.connect(level7).register(level8.address);

    const expectedPayments = [
        (amount * levelRatios[0]) / DESCALE,
        (amount * levelRatios[1]) / DESCALE,
        (amount * levelRatios[2]) / DESCALE,
        (amount * levelRatios[3]) / DESCALE,
        (amount * levelRatios[4]) / DESCALE,
        (amount * levelRatios[5]) / DESCALE,
        (amount * levelRatios[6]) / DESCALE,
    ];
  
    // Approve and send payment to the 7th level
    let remaining = amount - (expectedPayments[5] + expectedPayments[4] + expectedPayments[3] + expectedPayments[2] + expectedPayments[1] + expectedPayments[0]);
    await currency.connect(deployer).approve(affiliates.target, amount);
    await expect(affiliates.connect(deployer).sendPayment(level7.address, amount))
        .to.emit(affiliates, "FounderPaymentReceived")
        .withArgs(remaining);

    const paymentLevel1 = await affiliates.paymentBook(level1.address);
    expect(paymentLevel1).to.equal(expectedPayments[5]);
  
    const paymentLevel2 = await affiliates.paymentBook(level2.address);
    expect(paymentLevel2).to.equal(expectedPayments[4]);
  
    const paymentLevel3 = await affiliates.paymentBook(level3.address);
    expect(paymentLevel3).to.equal(expectedPayments[3]);
  
    const paymentLevel4 = await affiliates.paymentBook(level4.address);
    expect(paymentLevel4).to.equal(expectedPayments[2]);
  
    const paymentLevel5 = await affiliates.paymentBook(level5.address);
    expect(paymentLevel5).to.equal(expectedPayments[1]);
  
    const paymentLevel6 = await affiliates.paymentBook(level6.address);
    expect(paymentLevel6).to.equal(expectedPayments[0]);
  
    //const paymentLevel7 = await affiliates.paymentBook(level7.address);
    //expect(paymentLevel7).to.equal(expectedPayments[0]);
  
    // Verify no extra payments are left unallocated
    const totalPaid = expectedPayments.reduce((acc, curr) => acc + curr, BigInt(0));
    const founderPayment = await affiliates.paymentBook(founder.target);
    expect(founderPayment).to.equal(amount - totalPaid);
  });

});