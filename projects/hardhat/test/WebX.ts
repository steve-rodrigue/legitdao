const { expect } = require("chai");
const { ethers } = require("hardhat");
import { ethers as ethersUtils } from "ethers";
import { WebX } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("WebX Contract", function () {
  let webX: WebX;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;

  beforeEach(async () => {
    const WebX = await ethers.getContractFactory("WebX");
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    webX = await WebX.deploy();
  });

  it("Should deploy with the correct initial supply", async () => {
    const totalSupply = await webX.totalSupply();
    expect(totalSupply).to.equal(ethersUtils.parseEther("100000000"));
  });

  it("Should allow creating a buy offer", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);
    const value = price * amount;

    await expect(webX.connect(addr1).createBuyOffer(price, amount, { value }))
      .to.emit(webX, "BuyOfferCreated")
      .withArgs(0, addr1.address, price, amount);

    const offer = await webX.getOffer(0);
    expect(offer.user).to.equal(addr1.address);
    expect(offer.price).to.equal(price);
    expect(offer.amount).to.equal(amount);
    expect(offer.isBuy).to.be.true;
  });

  it("Should fail when incorrect BNB is sent", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);
    const incorrectValue = price * (amount - BigInt(10));

    await expect(
        webX.connect(addr1).createBuyOffer(price, amount, { value: incorrectValue })
    ).to.be.revertedWith("Incorrect BNB sent");
});

it("Should fail when price is zero", async () => {
    const price = 0;
    const amount = 100;
    const value = ethersUtils.parseEther("0");

    await expect(
        webX.connect(addr1).createBuyOffer(price, amount, { value })
    ).to.be.revertedWith("Invalid price or amount");
});

it("Should fail when amount is zero", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(0);
    const value = price * amount;

    await expect(
        webX.connect(addr1).createBuyOffer(price, amount, { value })
    ).to.be.revertedWith("Invalid price or amount");
  });

  it("Should allow withdrawing a buy offer and refunding BNB", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);
    const value = price * amount;

    await webX.connect(addr1).createBuyOffer(price, amount, { value });

    const balanceBefore = await ethers.provider.getBalance(addr1);
    const tx = await webX.connect(addr1).withdrawOffer(0);
    const receipt = await tx.wait();
    const gasUsed = BigInt(receipt?.gasUsed ? receipt.gasUsed.toString() : "0");
    const gasCost = gasUsed * BigInt(tx.gasPrice.toString());

    const balanceAfter = await ethers.provider.getBalance(addr1);

    expect(balanceAfter).to.equal(balanceBefore + value - gasCost);
    const offer = await webX.getOffer(0);
    expect(offer.amount).to.equal(0); // Offer is deleted
  });

  it("Should fail when trying to withdraw an offer not owned by the caller", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);

    // addr1 creates a buy offer
    await webX.connect(addr1).createBuyOffer(price, amount, { value: price * amount });

    // addr2 attempts to withdraw addr1's offer
    await expect(webX.connect(addr2).withdrawOffer(0)).to.be.revertedWith("Not your offer");
  });

  it("Should fail when trying to withdraw an already fulfilled or withdrawn offer", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);

    // addr1 creates a buy offer
    await webX.connect(addr1).createBuyOffer(price, amount, { value: price * amount });

    // addr1 withdraws the offer
    await webX.connect(addr1).withdrawOffer(0);

    // addr1 attempts to withdraw the same offer again
    await expect(webX.connect(addr1).withdrawOffer(0)).to.be.revertedWith("Offer already fulfilled or withdrawn");
  });

  it("Should allow creating a sell offer", async () => {
    const amount = 100;
    const price = ethersUtils.parseEther("0.02");

    await webX.connect(owner).approve(webX.target, amount);

    await expect(webX.connect(owner).createSellOffer(price, amount))
      .to.emit(webX, "SellOfferCreated")
      .withArgs(0, owner.address, price, amount);

    const offer = await webX.getOffer(0);
    expect(offer.user).to.equal(owner.address);
    expect(offer.price).to.equal(price);
    expect(offer.amount).to.equal(amount);
    expect(offer.isBuy).to.be.false;
  });

  it("Should allow creating and withdrawing a sell offer", async () => {
    const price = ethersUtils.parseEther("0.01"); // Price per token
    const amount = 100; // Amount of tokens to sell

    // Mint tokens to addr1
    await webX.transfer(addr1.address, amount);

    // Approve the contract to spend tokens on behalf of addr1
    await webX.connect(addr1).approve(webX.target, amount);

    // Create a sell offer
    const txCreate = await webX.connect(addr1).createSellOffer(price, amount);

    // Verify that the offer was created
    const offer = await webX.getOffer(0);
    expect(offer.user).to.equal(addr1.address);
    expect(offer.price).to.equal(price);
    expect(offer.amount).to.equal(amount);
    expect(offer.isBuy).to.be.false;

    // Withdraw the sell offer
    const txWithdraw = await webX.connect(addr1).withdrawOffer(0);
    const receiptWithdraw = await txWithdraw.wait();

    // Verify the offer was withdrawn
    const withdrawnOffer = await webX.getOffer(0);
    expect(withdrawnOffer.amount).to.equal(0); // The offer is deleted
  });

  it("Should fail when amount is zero", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = 0;

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Invalid amount");
});

it("Should fail when price is zero", async () => {
    const price = 0;
    const amount = 100;

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Invalid price");
});

it("Should fail when token balance is insufficient", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = 100;

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Insufficient token balance");
});

it("Should fail when allowance is insufficient", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = 50;

    // Mint tokens to addr1
    await webX.transfer(addr1.address, amount);

    // Do not approve the contract
    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Insufficient allowance");
  });

  it("Should fail if no matching buy offers are found for sell orders", async () => {
    const amountSell = 100;
    await webX.connect(owner).approve(webX.target, amountSell);

    await expect(
      webX.connect(owner).matchSellOrder(amountSell, ethersUtils.parseEther("0.02"))
    ).to.be.revertedWith("No matching buy offers found");
  });

  it("Should return the correct user offers", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);
    const value = price * amount;

    await webX.connect(addr1).createBuyOffer(price, amount, { value });

    const userOffers = await webX.getUserOffers(addr1.address);
    expect(userOffers.length).to.equal(1);
    expect(userOffers[0]).to.equal(0);
  });

  it("Should fail when amountToSell is zero", async () => {
    const amountToSell = 0; // Invalid amount
    const minPrice = ethersUtils.parseEther("0.005");

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Invalid amount");
});

it("Should fail when token balance is insufficient", async () => {
    const amountToSell = 150; // Exceeds balance
    const minPrice = ethersUtils.parseEther("0.005");

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Insufficient token balance");
});

it("Should fail when allowance is insufficient", async () => {
    const amountToSell = BigInt(50); // Valid amount
    const minPrice = ethersUtils.parseEther("0.005");

    // Mint tokens to addr2
    await webX.transfer(addr2.address, amountToSell);

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Insufficient allowance");
});

it("Should fail when no matching buy offers are found", async () => {
    const amountToSell = BigInt(50);
    const minPrice = ethersUtils.parseEther("0.02"); // Higher than any buy offer

    // Mint tokens to addr2
    await webX.transfer(addr2.address, amountToSell);

    // Approve the contract to spend addr2's tokens
    await webX.connect(addr2).approve(webX.target, amountToSell);

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("No matching buy offers found");
});

it("Should match and sell tokens for valid buy offers", async () => {
    const amountToSell = BigInt(50);
    const price = ethersUtils.parseEther("0.01");
    const amountBuy = BigInt(100);
    const amountSell = BigInt(50);
    const minPrice = ethersUtils.parseEther("0.005"); // Matches buy offer
    const value = price * amountBuy;

    // Mint tokens to addr2
    await webX.transfer(addr2.address, amountToSell);

    // Approve the contract to spend addr2's tokens
    await webX.connect(addr2).approve(webX.target, amountToSell);

    // create the buy ofer:
    await webX.connect(addr1).createBuyOffer(price, amountBuy, { value });

    const sellerBalanceBefore = await ethers.provider.getBalance(addr2.address);

    const tx = await webX.connect(addr2).matchSellOrder(amountToSell, minPrice);
    const receipt = await tx.wait();
    const gasUsed = BigInt(receipt?.gasUsed ? receipt.gasUsed.toString() : "0");
    const gasCost = gasUsed * BigInt(tx.gasPrice.toString());

    const sellerBalanceAfter = await ethers.provider.getBalance(addr2.address);

    // Calculate expected earnings
    const expectedEarnings = price * amountToSell;

    expect(sellerBalanceAfter).to.equal(sellerBalanceBefore + expectedEarnings - gasCost);

    // Verify buy offer was updated
    const offer = await webX.getOffer(0);
    expect(offer.amount).to.equal(amountBuy - amountSell);

    // Emit event check
    await expect(tx)
        .to.emit(webX, "TokensSold")
        .withArgs(addr2.address, amountToSell, expectedEarnings);
});

it("Should partially match sell order if buy offers are insufficient", async () => {
    const amountToSell = BigInt(150); // More than available buy offer
    const price = ethersUtils.parseEther("0.01");
    const amountBuy = BigInt(100);
    const minPrice = ethersUtils.parseEther("0.005");
    const value = price * amountBuy;

    // Mint tokens to addr2
    await webX.transfer(addr2.address, amountToSell);

    // Approve the contract to spend addr2's tokens
    await webX.connect(addr2).approve(webX.target, amountToSell);

    // create the buy ofer:
    await webX.connect(addr1).createBuyOffer(price, amountBuy, { value });

    const sellerBalanceBefore = await ethers.provider.getBalance(addr2.address);

    const tx = await webX.connect(addr2).matchSellOrder(amountToSell, minPrice);
    const receipt = await tx.wait();
    const gasUsed = BigInt(receipt?.gasUsed ? receipt.gasUsed.toString() : "0");
    const gasCost = gasUsed * BigInt(tx.gasPrice.toString());

    const sellerBalanceAfter = await ethers.provider.getBalance(addr2.address);

    // Calculate expected earnings
    const expectedEarnings = price* amountBuy; // Full buy offer value

    expect(sellerBalanceAfter).to.equal(sellerBalanceBefore + expectedEarnings - gasCost);

    // Verify buy offer was fully consumed
    const offer = await webX.getOffer(0);
    expect(offer.amount).to.equal(0); // Offer is deleted

    // Emit event check
    await expect(tx)
        .to.emit(webX, "TokensSold")
        .withArgs(addr2.address, amountBuy, expectedEarnings);
  });

  it("Should skip offers that do not meet the criteria", async () => {
    const validPrice = ethersUtils.parseEther("0.01");
    const invalidPrice = ethersUtils.parseEther("0.005"); // Below minimum price
    const amountBuy = BigInt(100);
    const amountSell = BigInt(50);
    const valueValid = validPrice * amountBuy;
    const valueInvalid = invalidPrice * amountBuy;

    // Create two buy offers: one valid and one invalid
    await webX.connect(addr2).createBuyOffer(invalidPrice, amountBuy, { value: valueInvalid });
    await webX.connect(addr1).createBuyOffer(validPrice, amountBuy, { value: valueValid });

    // Mint tokens to addr3
    await webX.transfer(addr3.address, amountSell);

    // Approve the contract to spend addr3's tokens
    await webX.connect(addr3).approve(webX.target, amountSell);

    // Match sell order with a minimum price that excludes the second offer
    const minPrice = ethersUtils.parseEther("0.01"); // Excludes the second offer
    const tx = await webX.connect(addr3).matchSellOrder(amountSell, minPrice);
    const receipt = await tx.wait();

    // Verify that only the valid offer was matched
    const remainingOffer1 = await webX.getOffer(0);
    const remainingOffer2 = await webX.getOffer(1);

    expect(remainingOffer1.amount).to.equal(amountBuy); // Skipped
    expect(remainingOffer2.amount).to.equal(amountBuy - amountSell); // Partially fulfilled

    // Check emitted event
    const expectedEarnings = validPrice * amountSell;
    await expect(tx)
        .to.emit(webX, "TokensSold")
        .withArgs(addr3.address, amountSell, expectedEarnings);
  });
});