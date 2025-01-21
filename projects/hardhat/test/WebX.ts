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
  let oneYearInSeconds: number;
  let amountOfSecondsInPeriod: number;
  let tokensPerPeriod: number;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    wallet1 = await owner.getAddress();

    const WebX = await ethers.getContractFactory("WebX");
    webX = await WebX.deploy();

    oneYearInSeconds = 365 * 24 * 60 * 60;
    amountOfSecondsInPeriod = 21600;
    tokensPerPeriod = 3240;
  });

  it("should return the correct token URI", async () => {
    const tokenURI = await webX.tokenURI();
    expect(tokenURI).to.equal("https://legitdao.com/contracts/webx.json");
  });

  it("should distribute allocation to 10 addresses and mint correctly", async () => {
    // Generate random addresses
    let addresses: string[] = [];
    let amountOfAddresses = 10;
    for (let i = 0; i < amountOfAddresses; i++) {
        const wallet = ethers.Wallet.createRandom();
        addresses.push(wallet.address);
    }

    // Initial allocation
    const initialAllocation = await webX.getAllocatedBlocks(owner.address);

    // Attribute 1 unit of allocation (out of the TOKENS_PER_PERIOD) to each address
    const blocksToAttribute = Math.floor(tokensPerPeriod / addresses.length);

    // Attribute a blocks to each address
    for (const addr of addresses) {
        await webX.connect(owner).attributeMintingBlock(addr, blocksToAttribute)
    }

    // Simulate 1 year of elapsed time in seconds
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Execute mint
    await webX.mint();

    // Verify that allocations add up correctly
    const remainingAllocation = await webX.getAllocatedBlocks(owner.address);
    const totalAttributed = BigInt(amountOfAddresses) * BigInt(blocksToAttribute);
    expect(remainingAllocation + totalAttributed).to.equal(initialAllocation);
    

    // Verify balances of the first 10 attributed addresses
    const amountOfPeriods = oneYearInSeconds / amountOfSecondsInPeriod;
    const totalTokens = amountOfPeriods * tokensPerPeriod;
    const percentToAtttribute = blocksToAttribute / tokensPerPeriod;
    const expectedMintedPerAddress = totalTokens *  percentToAtttribute;
    for (let i = 0; i < 10; i++) {
        const balance = await webX.balanceOfInToken(addresses[i]);
        expect(balance).to.equal(expectedMintedPerAddress);
    }

    // Check mintable tokens
    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0);
  });

  it("should mint tokens and emit TokenMinted event", async () => {
    // Simulate time passing (1 year)
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change
    
    // Expected values
    const totalSupply = await webX.TOTAL_SUPPLY();
    const tokensToMint = totalSupply / BigInt(20);
    const remainingToMing = totalSupply - tokensToMint;

    // Call mint function
    const tx = await webX.mint();

    // Check TokenMinted event
    await expect(tx)
        .to.emit(webX, "TokenMinted")
        .withArgs(
            tokensToMint.toString(),
            remainingToMing.toString(),
            tokensToMint.toString()
        );

    // Check balances
    const ownerBalance = await webX.balanceOf(owner.address);
    expect(ownerBalance).to.equal(tokensToMint.toString());

    // Check total minted tokens
    const totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(tokensToMint.toString());
  });

  it("should remove sender from allocatedWallets when allocation reaches zero", async () => {
    const senderInitialAllocation = await webX.getAllocatedBlocks(owner.address);
  
    // Attribute entire allocation from owner to addr1
    await webX.connect(owner).attributeMintingBlock(addr1.address, senderInitialAllocation);
  
    // Fetch updated allocated wallets directly
    const allocatedWalletCount = await webX.allocatedWalletsLength(); // Assuming a helper function
    const allocatedWallets = [];
    for (let i = 0; i < allocatedWalletCount; i++) {
      allocatedWallets.push(await webX.allocatedWallets(i));
    }
  
    // Verify that owner is no longer in the list
    expect(allocatedWallets).to.not.include(owner.address);
  
    // Verify that owner's allocation is zero
    const ownerAllocation = await webX.getAllocatedBlocks(owner.address);
    expect(ownerAllocation).to.equal(0);
  });
  
  it("should update allocatedWallets array correctly when removing sender", async () => {
    // Verify initial state
    const initialWalletCount = await webX.allocatedWalletsLength();
    expect(initialWalletCount).to.be.gte(1);
  
    // Attribute entire allocation from owner to addr2
    const addr1InitialAllocation = await webX.getAllocatedBlocks(owner.address);
    await webX.connect(owner).attributeMintingBlock(addr2.address, addr1InitialAllocation);
  
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
    await webX.connect(owner).attributeMintingBlock(addr3, 1);

    // Attribute the entire allocation from the owner to addr1
    const senderInitialAllocation = await webX.getAllocatedBlocks(owner.address);
    await webX.connect(owner).attributeMintingBlock(addr1.address, senderInitialAllocation);

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
    const senderInitialAllocation = await webX.getAllocatedBlocks(owner.address);
    await webX.connect(owner).attributeMintingBlock(addr1.address, senderInitialAllocation);
  
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
    const blocksToAttribute = 57;

    // Get initial allocations
    const initialSenderAllocation = await webX.allocationBlocks(owner.address);
    const initialReceiverAllocation = await webX.allocationBlocks(addr1.address);

    // Call the function
    const tx = await webX.connect(owner).attributeMintingBlock(addr1.address, blocksToAttribute);

    // Calculate expected allocations after attribution
    let blocksInWei = await webX.blocksWorthInWei(blocksToAttribute);
    const expectedSenderAllocation = initialSenderAllocation - blocksInWei;
    const expectedReceiverAllocation = initialReceiverAllocation + blocksInWei;

    // Verify event emission with all five parameters
    await expect(tx)
      .to.emit(webX, "MintingRatioAttributed")
      .withArgs(
        owner.address,                   // sender
        addr1.address,                   // receiver
        expectedSenderAllocation,        // senderNewAmount
        expectedReceiverAllocation,      // receiverNewAmount
        blocksInWei            // transferred
      );
  });

  it("should allocate wallets correctly", async () => {
    const wallet1Allocation = await webX.allocationBlocks(wallet1);

    const tokensPerPeriod = await webX.TOKENS_PER_PERIOD();
    expect(wallet1Allocation).to.equal(tokensPerPeriod);

    const allocatedWallets = await webX.allocatedWallets(0);
    expect(allocatedWallets).to.equal(wallet1);
  });

  it("should calculate mintable tokens correctly", async () => {
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(ethersUtils.parseEther("94608000"));

    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0); // No time has elapsed yet
  });

  it("should not mint more than the total supply", async () => {
    // Simulate 20 years of minting:
    const twentyYearsInSeconds = 20 * oneYearInSeconds;
    await ethers.provider.send("evm_increaseTime", [twentyYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Call the mint function
    await webX.mint();

    // Simulate 1 year in seconds
    const twentyOneYearsInSeconds = 1 * oneYearInSeconds;
    await ethers.provider.send("evm_increaseTime", [twentyOneYearsInSeconds]);
    await ethers.provider.send("evm_mine", []); // Mine the next block to apply the time change

    // Attempt to mint again and verify it reverts
    await expect(webX.mint()).to.be.revertedWith("All tokens minted");

    // Verify that the total minted does not exceed the total supply
    const totalMinted = await webX.totalMinted();
    const totalSupply = await webX.totalSupply();

    // Assert that the total minted tokens equal the total supply
    expect(totalMinted).to.equal(totalSupply);

    // Check that mintableTokens is zero
    const mintableTokens = await webX.mintableTokens();
    expect(mintableTokens).to.equal(0);

    // Check remainingTokens is zero
    const remainingTokens = await webX.remainingTokens();
    expect(remainingTokens).to.equal(0);
  });

  it("should allow repeated minting over time", async () => {
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // First mint
    await webX.mint();

    const tokensPerPeriod = await webX.TOKENS_PER_PERIOD();

    // Expected values after the first mint
    const amountOfPeriods = oneYearInSeconds / amountOfSecondsInPeriod;
    const firstExpectedMinted = BigInt(amountOfPeriods) * tokensPerPeriod;

    let totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(firstExpectedMinted);

    // Simulate again
    await ethers.provider.send("evm_increaseTime", [oneYearInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Second mint
    await webX.mint();

    // Expected values after the second mint
    const secondExpectedMinted = firstExpectedMinted * BigInt(2);
    totalMinted = await webX.totalMinted();
    expect(totalMinted).to.equal(secondExpectedMinted);
  });

  it("should revert if no new tokens can be minted", async () => {
    // Simulate no time passing
    await ethers.provider.send("evm_increaseTime", [0]);
    await ethers.provider.send("evm_mine", []);

    await expect(webX.mint()).to.be.revertedWith("No Token to mint");
  });
  
  it("should correctly attribute blocks to an existing wallet", async () => {
    // Initial allocation for the owner and wallet2
    const ownerAllocation = await webX.getAllocatedBlocks(owner.address);
    const wallet2Allocation = await webX.getAllocatedBlocks(addr2.address);

    // Attribute 10 units of allocation (considering TOKENS_PER_PERIOD is now 570)
    const blocksToAttribute = 10; // Updated to align with the smaller allocation scale
    await webX.connect(owner).attributeMintingBlock(addr2.address, blocksToAttribute);

    // Check updated allocations
    const updatedOwnerAllocation = await webX.getAllocatedBlocks(owner.address);
    const updatedWallet2Allocation = await webX.getAllocatedBlocks(addr2.address);

    // Ensure the owner's allocation decreased and wallet2's allocation increased by the attributed blocks
    expect(updatedOwnerAllocation).to.equal(ownerAllocation - BigInt(blocksToAttribute));
    expect(updatedWallet2Allocation).to.equal(wallet2Allocation + BigInt(blocksToAttribute));

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
    const blocksToAttribute = 10000;
    await expect(
      webX.connect(owner).attributeMintingBlock("0x0000000000000000000000000000000000000000", blocksToAttribute)
    ).to.be.revertedWith("Cannot attribute to zero address");
  });

  it("should revert if attempting to attribute more than the available allocation", async () => {
    const blocksToAttribute = BigInt(3241); // Owner only has 3240
    await expect(
      webX.connect(owner).attributeMintingBlock(addr2.address, blocksToAttribute)
    ).to.be.revertedWith("Insufficient allocation to attribute");
  });

  it("should revert if attempting to attribute zero blocks", async () => {
    await expect(
      webX.connect(owner).attributeMintingBlock(addr2.address, 0)
    ).to.be.revertedWith("amountBlock must be greater than zero");
  });

  it("should add the recipient to allocatedWallets if not already present", async () => {
    // Attribute 10 units of allocation (considering TOKENS_PER_PERIOD is now 570)
    const blocksToAttribute = 10; // Updated allocation blocks
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

    // Attribute the blocks to addr1
    await webX.connect(owner).attributeMintingBlock(addr1.address, blocksToAttribute);

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
    const addr1Allocation = await webX.getAllocatedBlocks(addr1.address);
    expect(addr1Allocation).to.equal(blocksToAttribute);
  });

  it("should handle multiple attributions to the same wallet", async () => {
    const blocksToAttribute1 = 10; // Adjusted to align with the updated TOKENS_PER_PERIOD (570)
    const blocksToAttribute2 = 5;

    // Fetch initial owner allocation
    const initialOwnerAllocation = await webX.getAllocatedBlocks(owner.address);

    // First attribution
    await webX.connect(owner).attributeMintingBlock(addr2.address, blocksToAttribute1);

    // Second attribution
    await webX.connect(owner).attributeMintingBlock(addr2.address, blocksToAttribute2);

    // Check addr2's allocation
    const addr2Allocation = await webX.getAllocatedBlocks(addr2.address);
    const expectedAddr2Allocation = BigInt(blocksToAttribute1 + blocksToAttribute2);
    expect(addr2Allocation).to.equal(expectedAddr2Allocation);

    // Check owner's remaining allocation
    const expectedOwnerAllocation = initialOwnerAllocation - expectedAddr2Allocation;
    const ownerAllocation = await webX.getAllocatedBlocks(owner.address);
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

  it("should return zero token if balance is smaller than 1 token", async () => {
    // Simulate 20 years of minting:
    const twentyYearsInSeconds = 20 * oneYearInSeconds;
    await ethers.provider.send("evm_increaseTime", [twentyYearsInSeconds]);
    await ethers.provider.send("evm_mine", []);

    // Mint:
    await webX.mint();

    // Transfer some wei:
    await webX.connect(owner).transfer(addr1, 2);

    // balance address:
    let balanceAddress = await webX.balanceOfInToken(addr1);
    expect(balanceAddress).to.be.eq(0);

    // balance owner:
    let balanceOwner = await webX.balanceOfInToken(owner);
    expect(balanceOwner).to.be.eq(94608000 - 1);
  });
});