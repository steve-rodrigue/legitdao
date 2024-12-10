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
  let wallet1: string;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    wallet1 = await owner.getAddress();

    const WebX = await ethers.getContractFactory("WebX");
    webX = await WebX.deploy();
  });

  it("should return the correct token URI", async () => {
    const tokenURI = await webX.tokenURI();
    expect(tokenURI).to.equal("https://legitdao.com/contracts/webx.json");
  });

  it("should distribute allocation to 3240 addresses and mint correctly", async () => {
    // Generate random addresses
    let addresses: string[] = [];
    let amountOfAddresses = 3240;
    for (let i = 0; i < amountOfAddresses; i++) {
        const wallet = ethers.Wallet.createRandom();
        addresses.push(wallet.address);
    }

    // Initial allocation
    const initialAllocation = await webX.allocationPercentage(owner.address);

    // Attribute 1 unit of allocation (out of the DIVIDER) to each address
    const percentageToAttribute = Math.floor(Number(await webX.DIVIDER()) / addresses.length);

    // Attribute a percentage to each address
    for (const addr of addresses) {
        await webX.connect(owner).attributeMintingRatio(addr, percentageToAttribute);
    }

    // Simulate 1 year of elapsed time in seconds
    const oneYearInHours = 365 * 24; // 1 year in hours
    const oneYearInSeconds = oneYearInHours * 3600;
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Execute mint
    await webX.mint();

    // Verify that allocations add up correctly
    const remainingAllocation = await webX.allocationPercentage(owner.address);
    const totalAttributed = BigInt(amountOfAddresses) * BigInt(percentageToAttribute);
    expect(remainingAllocation + totalAttributed).to.equal(initialAllocation);

    // Verify balances of the first 10 attributed addresses
    const expectedMintablePerUnit = BigInt(await webX.TOTAL_SUPPLY()) / BigInt(await webX.MINTING_PERIOD()); // Tokens per hour
    const expectedMintedPerAddress = (expectedMintablePerUnit * BigInt(oneYearInHours) * BigInt(percentageToAttribute)) / BigInt(await webX.DIVIDER());

    for (let i = 0; i < 10; i++) {
        const balance = await webX.balanceOf(addresses[i]);
        expect(balance).to.equal(expectedMintedPerAddress);
    }
  });

  it("should mint tokens and emit TokenMinted event", async () => {
    // Simulate time passing (1 year)
    const oneYearInHours = 365 * 24; // Time in hours
    const oneYearInSeconds = oneYearInHours * 3600; // Convert to seconds
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Call mint function
    const tx = await webX.mint();

    // Expected values
    const mintingPeriod = await webX.MINTING_PERIOD();
    const totalSupply = await webX.TOTAL_SUPPLY();
    const mintablePerHour = BigInt(totalSupply) / BigInt(mintingPeriod); // Tokens per hour
    const expectedTotalMintable = mintablePerHour * BigInt(oneYearInHours); // Total tokens minted in 1 year
    const remainingToMint = BigInt(totalSupply) - BigInt(expectedTotalMintable); // Remaining tokens

    // Check TokenMinted event
    await expect(tx)
        .to.emit(webX, "TokenMinted")
        .withArgs(
            expectedTotalMintable.toString(),
            remainingToMint.toString(),
            expectedTotalMintable.toString()
        );

    // Check balances
    const ownerBalance = await webX.balanceOf(owner.address);
    expect(ownerBalance).to.equal(expectedTotalMintable.toString());

    // Check total minted tokens
    const totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(expectedTotalMintable.toString());
  });

  it("should remove sender from allocatedWallets when allocation reaches zero", async () => {
    const senderInitialAllocation = await webX.allocationPercentage(owner.address);
  
    // Attribute entire allocation from owner to addr1
    await webX.connect(owner).attributeMintingRatio(addr1.address, senderInitialAllocation);
  
    // Fetch updated allocated wallets directly
    const allocatedWalletCount = await webX.allocatedWalletsLength(); // Assuming a helper function
    const allocatedWallets = [];
    for (let i = 0; i < allocatedWalletCount; i++) {
      allocatedWallets.push(await webX.allocatedWallets(i));
    }
  
    // Verify that owner is no longer in the list
    expect(allocatedWallets).to.not.include(owner.address);
  
    // Verify that owner's allocation is zero
    const ownerAllocation = await webX.allocationPercentage(owner.address);
    expect(ownerAllocation).to.equal(0);
  });
  
  it("should update allocatedWallets array correctly when removing sender", async () => {
    // Verify initial state
    const initialWalletCount = await webX.allocatedWalletsLength();
    expect(initialWalletCount).to.be.gte(1);
  
    // Attribute entire allocation from owner to addr2
    const addr1InitialAllocation = await webX.allocationPercentage(owner.address);
    await webX.connect(owner).attributeMintingRatio(addr2.address, addr1InitialAllocation);
  
    // Fetch updated allocated wallets
    const updatedWallets = [];
    const updatedWalletCount = await webX.allocatedWalletsLength();
    for (let i = 0; i < updatedWalletCount; i++) {
      updatedWallets.push(await webX.allocatedWallets(i));
    }
  
    // Verify that addr1 has been removed and addr2 remains in the list
    expect(updatedWallets).to.not.include(owner.address);
    expect(updatedWallets).to.include(addr2.address);
  });
  
  it("should swap and update indexes correctly when sender is not the last wallet", async () => {
    // Add a new wallet to ensure the owner is not the last wallet
    const addr3 = ethers.Wallet.createRandom().address;
    await webX.connect(owner).attributeMintingRatio(addr3, 1);

    // Attribute the entire allocation from the owner to addr1
    const senderInitialAllocation = await webX.allocationPercentage(owner.address);
    await webX.connect(owner).attributeMintingRatio(addr1.address, senderInitialAllocation);

    // Fetch updated allocated wallets
    const updatedWalletCount = await webX.allocatedWalletsLength();
    const updatedWallets = [];
    for (let i = 0; i < updatedWalletCount; i++) {
        updatedWallets.push(await webX.allocatedWallets(i));
    }

    // Verify that the owner has been removed from the list
    expect(updatedWallets).to.not.include(owner.address);

    // Verify that the updated wallet count is correct
    expect(updatedWallets.length).to.equal(2); // Only addr1 and addr3 remain

    // Verify that addr3 has replaced the owner's position
    const walletAtIndex0 = await webX.allocatedWallets(0);
    expect(walletAtIndex0).to.equal(addr3);

    // Verify that addr1 remains in the list
    const walletAtIndex1 = await webX.allocatedWallets(1);
    expect(walletAtIndex1).to.equal(addr1.address);
  });
  
  it("should handle the case when sender is the last wallet in the array", async () => {
    // Ensure owner is the last wallet
    const allocatedWalletCount = await webX.allocatedWalletsLength();
    const lastWallet = await webX.allocatedWallets(allocatedWalletCount - BigInt(1));
    expect(lastWallet).to.equal(owner.address);
  
    // Attribute entire allocation from owner to addr1
    const senderInitialAllocation = await webX.allocationPercentage(owner.address);
    await webX.connect(owner).attributeMintingRatio(addr1.address, senderInitialAllocation);
  
    // Fetch updated allocated wallets
    const updatedWalletCount = await webX.allocatedWalletsLength();
    const updatedWallets = [];
    for (let i = 0; i < updatedWalletCount; i++) {
      updatedWallets.push(await webX.allocatedWallets(i));
    }
  
    // Verify that owner has been removed from the list
    expect(updatedWallets).to.not.include(owner.address);
  
    // Verify that addr1 and addr2 remain in the correct positions
    expect(updatedWallets[0]).to.equal(addr1.address);
  });

  it("should emit MintingRatioAttributed event when minting ratio is attributed", async () => {
    const percentageToAttribute = 57; // 10% of allocation

    // Get initial allocations
    const initialSenderAllocation = await webX.allocationPercentage(owner.address);
    const initialReceiverAllocation = await webX.allocationPercentage(addr1.address);

    // Call the function
    const tx = await webX.connect(owner).attributeMintingRatio(addr1.address, percentageToAttribute);

    // Calculate expected allocations after attribution
    const expectedSenderAllocation = initialSenderAllocation - BigInt(percentageToAttribute);
    const expectedReceiverAllocation = initialReceiverAllocation + BigInt(percentageToAttribute);

    // Verify event emission with all five parameters
    await expect(tx)
      .to.emit(webX, "MintingRatioAttributed")
      .withArgs(
        owner.address,                   // sender
        addr1.address,                   // receiver
        expectedSenderAllocation,        // senderNewAmount
        expectedReceiverAllocation,      // receiverNewAmount
        percentageToAttribute            // transferred
      );
  });

  it("should initialize with the correct parameters", async () => {
    const totalSupply = await webX.TOTAL_SUPPLY();
    const mintingPeriod = await webX.MINTING_PERIOD();
    const divider = await webX.DIVIDER();
    const startTime = await webX.startTime();

    // Updated expectations based on the latest contract changes
    expect(totalSupply).to.equal(ethersUtils.parseEther("94608000")); // Updated total supply
    expect(mintingPeriod).to.equal(20 * 365 * 4); // 20 years, 4 times per day
    expect(divider).to.equal(3240); // Updated divider for minting logic
    expect(startTime).to.be.gt(0); // startTime should be set
  });

  it("should allocate wallets correctly", async () => {
    const wallet1Allocation = await webX.allocationPercentage(wallet1);

    expect(wallet1Allocation).to.equal(3240);

    const allocatedWallets = await webX.allocatedWallets(0);
    expect(allocatedWallets).to.equal(wallet1);
  });

  it("should calculate mintable tokens correctly", async () => {
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(ethersUtils.parseEther("94608000"));

    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0); // No time has elapsed yet
  });

  it("should mint tokens proportionally over time", async () => {
    // Simulate time passing by 1 year (365 days * 24 hours)
    const oneYearInHours = 365 * 24;
    const oneYearInSeconds = oneYearInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]); // Increase time in seconds
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Call mint function
    await webX.mint();

    // Expected calculations
    const mintingPeriod = await webX.MINTING_PERIOD(); // Total minting period in hours
    const totalSupply = await webX.TOTAL_SUPPLY(); // Total supply
    const mintablePerHour = BigInt(totalSupply) / BigInt(mintingPeriod); // Tokens minted per hour
    const expectedMinted = mintablePerHour * BigInt(oneYearInHours); // Total minted for 1 year

    // Check the total minted tokens
    const totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(expectedMinted);

    // Check the wallet balance
    const wallet1Balance = await webX.balanceOf(wallet1);
    expect(wallet1Balance).to.equal(expectedMinted);
  });

  it("should not mint more than the total supply", async () => {
    // Simulate 21 years in seconds (21 years * 365 days * 24 hours * 60 minutes * 60 seconds)
    const twentyOneYearsInHours = 21 * 365 * 24; // Convert years to hours
    const twentyOneYearsInSeconds = twentyOneYearsInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [twentyOneYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Call the mint function
    await webX.mint();

    // Verify that the total minted does not exceed the total supply
    const totalMinted = await webX.totalMinted();
    const totalSupply = await webX.TOTAL_SUPPLY();

    // Assert that the total minted tokens equal the total supply
    expect(totalMinted).to.equal(totalSupply);

    // Attempt to mint again and verify it reverts
    await expect(webX.mint()).to.be.revertedWith("All tokens minted");

    // Check that mintableTokens is zero
    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0);

    // Check remainingTokens is zero
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(0);
  });

  it("should not mint more than TOTAL_SUPPLY", async () => {
    // Simulate 21 years to exceed the minting period
    const twentyOneYearsInHours = 21 * 365 * 24; // Convert 21 years to hours
    const twentyOneYearsInSeconds = twentyOneYearsInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [twentyOneYearsInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Call mint function
    await webX.mint();

    // Verify total minted tokens match the total supply
    const totalMinted = await webX.totalMinted();
    const totalSupply = await webX.TOTAL_SUPPLY();
    expect(totalMinted).to.equal(totalSupply);

    // Verify allocations for the first wallet
    const totalWallets = await webX.allocatedWalletsLength();
    let totalMintedForWallets = BigInt(0);

    for (let i = 0; i < totalWallets; i++) {
        const walletAddress = await webX.allocatedWallets(i);
        const walletBalance = await webX.balanceOf(walletAddress);
        totalMintedForWallets += BigInt(walletBalance);
    }

    // Ensure the total distributed matches the total supply
    expect(totalMintedForWallets).to.equal(BigInt(totalSupply));
  });

  it("should allow repeated minting over time", async () => {
    // Simulate 6 months (half a year in hours)
    const sixMonthsInHours = (365 * 24) / 2; // Half a year in hours
    const sixMonthsInSeconds = sixMonthsInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [sixMonthsInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // First mint
    await webX.mint();

    // Expected values after the first mint
    const mintingPeriod = await webX.MINTING_PERIOD();
    const totalSupply = await webX.TOTAL_SUPPLY();
    const mintablePerHour = BigInt(totalSupply) / BigInt(mintingPeriod); // Tokens minted per hour
    const firstExpectedMinted = mintablePerHour * BigInt(sixMonthsInHours); // Minted for 6 months

    let totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(firstExpectedMinted);

    // Simulate another 6 months
    await ethers.provider.send("evm_increaseTime", [sixMonthsInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Second mint
    await webX.mint();

    // Expected values after the second mint
    const secondExpectedMinted = mintablePerHour * BigInt(2 * sixMonthsInHours); // Minted for 1 year total

    totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(secondExpectedMinted);
  });

  it("should revert if all tokens have already been minted", async () => {
    // Simulate 21 years to exceed the minting period
    const twentyOneYearsInHours = 21 * 365 * 24; // Convert 21 years to hours
    const twentyOneYearsInSeconds = twentyOneYearsInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [twentyOneYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
  
    // Mint all tokens
    await webX.mint();
  
    // Verify all tokens have been minted
    const totalMinted = await webX.totalMinted();
    const totalSupply = await webX.TOTAL_SUPPLY();
    expect(totalMinted).to.equal(totalSupply); // Total minted equals total supply
  
    // Attempt to mint again and expect it to revert
    await expect(webX.mint()).to.be.revertedWith("All tokens minted");
  
    // Verify mintableTokens is zero
    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0);

    // Verify remainingTokens is zero
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(0);
  });

  it("should revert if no new tokens can be minted", async () => {
    // Simulate no time passing
    await ethers.provider.send("evm_increaseTime", [0]);
    await ethers.provider.send("evm_mine", []);

    await expect(webX.mint()).to.be.revertedWith("No new tokens to mint");
  });

  it("should handle remainingTokens and mintableTokens correctly", async () => {
    // Simulate time passing (10 years in hours)
    const tenYearsInHours = 10 * 365 * 2; // Convert 10 years to 12 hours
    const tenYearsInSeconds = tenYearsInHours * 3600; // Convert hours to seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Expected values
    const totalSupply = await webX.TOTAL_SUPPLY();
    const mintingPeriod = await webX.MINTING_PERIOD(); // Minting period in hours
    const mintablePerHour = BigInt(totalSupply) / BigInt(mintingPeriod); // Tokens minted per hour
    const expectedMintableTokens = mintablePerHour * BigInt(tenYearsInHours); // Tokens mintable in 10 years
    const expectedRemainingTokens = BigInt(totalSupply) - expectedMintableTokens; // Remaining tokens

    // Check mintable tokens
    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(expectedMintableTokens);

    // Call the mint function
    await webX.mint();

    // Check remaining tokens
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(expectedRemainingTokens);
  });

  it("should correctly attribute percentage to an existing wallet", async () => {
    // Initial allocation for the owner and wallet2
    const ownerAllocation = await webX.allocationPercentage(owner.address);
    const wallet2Allocation = await webX.allocationPercentage(addr2.address);

    // Attribute 10 units of allocation (considering DIVIDER is now 570)
    const percentageToAttribute = 10; // Updated to align with the smaller allocation scale
    await webX.connect(owner).attributeMintingRatio(addr2.address, percentageToAttribute);

    // Check updated allocations
    const updatedOwnerAllocation = await webX.allocationPercentage(owner.address);
    const updatedWallet2Allocation = await webX.allocationPercentage(addr2.address);

    // Ensure the owner's allocation decreased and wallet2's allocation increased by the attributed percentage
    expect(updatedOwnerAllocation).to.equal(ownerAllocation - BigInt(percentageToAttribute));
    expect(updatedWallet2Allocation).to.equal(wallet2Allocation + BigInt(percentageToAttribute));

    // Ensure addr2 remains in the allocatedWallets array
    const walletCount = await webX.allocatedWalletsLength();
    let walletExists = false;
    for (let i = 0; i < walletCount; i++) {
        const wallet = await webX.allocatedWallets(i);
        if (wallet === addr2.address) {
            walletExists = true;
            break;
        }
    }
    expect(walletExists).to.be.true;
  });

  it("should revert if attempting to attribute to the zero address", async () => {
    const percentageToAttribute = 10000;
    await expect(
      webX.connect(owner).attributeMintingRatio("0x0000000000000000000000000000000000000000", percentageToAttribute)
    ).to.be.revertedWith("Cannot attribute to zero address");
  });

  it("should revert if attempting to attribute more than the available allocation", async () => {
    const percentageToAttribute = 99864001; // Owner only has 99864000
    await expect(
      webX.connect(owner).attributeMintingRatio(addr2.address, percentageToAttribute)
    ).to.be.revertedWith("Insufficient allocation to attribute");
  });

  it("should revert if attempting to attribute zero percentage", async () => {
    await expect(
      webX.connect(owner).attributeMintingRatio(addr2.address, 0)
    ).to.be.revertedWith("Percentage must be greater than zero");
  });

  it("should add the recipient to allocatedWallets if not already present", async () => {
    // Attribute 10 units of allocation (considering DIVIDER is now 570)
    const percentageToAttribute = 10; // Updated allocation percentage
    const initialAllocatedWalletsCount = await webX.allocatedWalletsLength();

    // Ensure addr1 is not already in the allocatedWallets
    let addr1Exists = false;
    for (let i = 0; i < initialAllocatedWalletsCount; i++) {
        const wallet = await webX.allocatedWallets(i);
        if (wallet === addr1.address) {
            addr1Exists = true;
            break;
        }
    }
    expect(addr1Exists).to.be.false;

    // Attribute the percentage to addr1
    await webX.connect(owner).attributeMintingRatio(addr1.address, percentageToAttribute);

    // Verify that addr1 is added to allocatedWallets
    const updatedAllocatedWalletsCount = await webX.allocatedWalletsLength();
    expect(updatedAllocatedWalletsCount).to.equal(initialAllocatedWalletsCount + BigInt(1));

    let addr1Added = false;
    for (let i = 0; i < updatedAllocatedWalletsCount; i++) {
        const wallet = await webX.allocatedWallets(i);
        if (wallet === addr1.address) {
            addr1Added = true;
            break;
        }
    }
    expect(addr1Added).to.be.true;

    // Verify addr1's allocation
    const addr1Allocation = await webX.allocationPercentage(addr1.address);
    expect(addr1Allocation).to.equal(percentageToAttribute);
  });

  it("should handle multiple attributions to the same wallet", async () => {
    const percentageToAttribute1 = 10; // Adjusted to align with the updated DIVIDER (570)
    const percentageToAttribute2 = 5;

    // Fetch initial owner allocation
    const initialOwnerAllocation = await webX.allocationPercentage(owner.address);

    // First attribution
    await webX.connect(owner).attributeMintingRatio(addr2.address, percentageToAttribute1);

    // Second attribution
    await webX.connect(owner).attributeMintingRatio(addr2.address, percentageToAttribute2);

    // Check addr2's allocation
    const addr2Allocation = await webX.allocationPercentage(addr2.address);
    const expectedAddr2Allocation = BigInt(percentageToAttribute1 + percentageToAttribute2);
    expect(addr2Allocation).to.equal(expectedAddr2Allocation);

    // Check owner's remaining allocation
    const expectedOwnerAllocation = initialOwnerAllocation - expectedAddr2Allocation;
    const ownerAllocation = await webX.allocationPercentage(owner.address);
    expect(ownerAllocation).to.equal(expectedOwnerAllocation);

    // Ensure addr2 is still in allocatedWallets
    const walletCount = await webX.allocatedWalletsLength();
    let walletExists = false;
    for (let i = 0; i < walletCount; i++) {
        const wallet = await webX.allocatedWallets(i);
        if (wallet === addr2.address) {
            walletExists = true;
            break;
        }
    }
    expect(walletExists).to.be.true;
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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Invalid amount");
});

it("Should fail when price is zero", async () => {
    const price = 0;
    const amount = 100;

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Invalid price");
});

it("Should fail when token balance is insufficient", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = 100;

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Insufficient token balance");
});

it("Should fail when allowance is insufficient", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = 50;

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    // Mint tokens to addr1
    await webX.transfer(addr1.address, amount);

    // Do not approve the contract
    await expect(
        webX.connect(addr1).createSellOffer(price, amount)
    ).to.be.revertedWith("Insufficient allowance");
  });

  it("Should fail if no matching buy offers are found for sell orders", async () => {
    const amountSell = 100;
    
    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    // Approve
    await webX.connect(owner).approve(webX.target, amountSell);

    await expect(
      webX.connect(owner).matchSellOrder(amountSell, ethersUtils.parseEther("0.02"))
    ).to.be.revertedWith("No matching buy offers found");
  });

  it("Should return the correct user offers", async () => {
    const price = ethersUtils.parseEther("0.01");
    const amount = BigInt(100);
    const value = price * amount;

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    // Create buy offer
    await webX.connect(addr1).createBuyOffer(price, amount, { value });

    const userOffers = await webX.getUserOffers(addr1.address);
    expect(userOffers.length).to.equal(1);
    expect(userOffers[0]).to.equal(0);
  });

  it("Should fail when amountToSell is zero", async () => {
    const amountToSell = 0; // Invalid amount
    const minPrice = ethersUtils.parseEther("0.005");

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Invalid amount");
});

it("Should fail when token balance is insufficient", async () => {
    const amountToSell = 150; // Exceeds balance
    const minPrice = ethersUtils.parseEther("0.005");

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Insufficient token balance");
});

it("Should fail when allowance is insufficient", async () => {
    const amountToSell = BigInt(50); // Valid amount
    const minPrice = ethersUtils.parseEther("0.005");

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    // Mint tokens to addr2
    await webX.transfer(addr2.address, amountToSell);

    await expect(
        webX.connect(addr2).matchSellOrder(amountToSell, minPrice)
    ).to.be.revertedWith("Insufficient allowance");
});

it("Should fail when no matching buy offers are found", async () => {
    const amountToSell = BigInt(50);
    const minPrice = ethersUtils.parseEther("0.02"); // Higher than any buy offer

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

    // Transfer
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

    // Simulate time passing, then mint
    const tenYearsInSeconds = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    await ethers.provider.send("evm_increaseTime", [tenYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    await webX.connect(owner).mint();

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