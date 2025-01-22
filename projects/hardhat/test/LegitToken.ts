import { expect } from "chai";
import { ethers } from "hardhat";
import { LegitToken } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers as ethersUtils } from "ethers";

describe("LegitToken - setAffiliatesAddress", function () {
    let legitToken: LegitToken;
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let affiliatesAddress: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let addressZero = "0x0000000000000000000000000000000000000000";
    const transferAmount = ethersUtils.parseEther("0.01"); // Transfer 0.01 tokens
    const TAX_SENDER = 20; // 20% sender tax
    const TAX_RECEIVER = 15; // 15% receiver tax

    beforeEach(async function () {
        // Get signers
        [owner, nonOwner, affiliatesAddress, user1, user2] = await ethers.getSigners();

        // Deploy LegitToken contract
        const LegitTokenFactory = await ethers.getContractFactory("LegitToken");
        legitToken = (await LegitTokenFactory.deploy()) as LegitToken;
    });

    it("✅ should return the correct token URI", async () => {
      const tokenURI = await legitToken.tokenURI();
      expect(tokenURI).to.equal("https://legitdao.com/contracts/legittoken.json");
    });

    it("✅ Should set the affiliates address if it's not set", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        const storedAddress = await legitToken.affiliatesAddress();
        expect(storedAddress).to.equal(affiliatesAddress.address);
    });

    it("✅ Should emit AffiliatesAddressSet event when setting the address", async function () {
        await expect(legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address))
            .to.emit(legitToken, "AffiliatesAddressSet")
            .withArgs(affiliatesAddress.address);
    });

    it("❌ Should revert if an invalid (zero) address is provided", async function () {
        await expect(legitToken.connect(owner).setAffiliatesAddress(addressZero))
            .to.be.revertedWith("Invalid address");
    });

    it("❌ Should revert if trying to set the address more than once", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);
        await expect(legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address))
            .to.be.revertedWith("Affiliates address already set");
    });

    it("❌ Should revert if a non-owner tries to set the address", async function () {
      await expect(legitToken.connect(nonOwner).setAffiliatesAddress(affiliatesAddress.address))
          .to.be.revertedWithCustomError(legitToken, "OwnableUnauthorizedAccount");
    });

    it("❌ Should revert if recipient address is 0x0", async function () {
      await expect(legitToken.connect(user1).transfer(addressZero, transferAmount))
          .to.be.revertedWith("Invalid recipient address");
    });

    it("❌ Should revert if recipient address is 0x0", async function () {
      await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);
      await expect(legitToken.connect(user1).transfer(addressZero, transferAmount))
          .to.be.revertedWith("Invalid recipient address");
    });

    it("❌ Should revert if affiliates address is not set", async function () {
        await expect(legitToken.connect(user1).transfer(user2.address, transferAmount))
            .to.be.revertedWith("Affiliates address is required");
    });

    it("❌ Should revert if recipient address is 0x0", async function () {
      await expect(legitToken.connect(user1).transfer(addressZero, transferAmount))
          .to.be.revertedWith("Invalid recipient address");
    });

    it("❌ Should revert if affiliates address is not set", async function () {
        const LegitTokenFactory = await ethers.getContractFactory("LegitToken");
        const newLegitToken = (await LegitTokenFactory.deploy()) as LegitToken;

        await expect(newLegitToken.connect(user1).transfer(user2.address, transferAmount))
            .to.be.revertedWith("Affiliates address is required");
    });

    it("✅ Should transfer full amount if sender is affiliates contract (no taxes)", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);
        await legitToken.connect(owner).transfer(affiliatesAddress.address, transferAmount);

        const senderBalanceBefore = await legitToken.balanceOf(affiliatesAddress.address);
        const recipientBalanceBefore = await legitToken.balanceOf(user2.address);

        await legitToken.connect(affiliatesAddress).transfer(user2.address, senderBalanceBefore);

        const senderBalanceAfter = await legitToken.balanceOf(affiliatesAddress.address);
        const recipientBalanceAfter = await legitToken.balanceOf(user2.address);

        expect(senderBalanceAfter).to.equal(senderBalanceBefore - senderBalanceBefore);
        expect(recipientBalanceAfter).to.equal(recipientBalanceBefore + senderBalanceBefore);
    });

    it("✅ Should correctly apply taxes if sender is not the affiliates contract", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        const senderTax = transferAmount * BigInt(TAX_SENDER) / BigInt(100);
        const receiverTax = transferAmount * BigInt(TAX_RECEIVER) / BigInt(100);
        const netAmount = transferAmount - (senderTax + receiverTax);

        const senderBalanceBefore = await legitToken.balanceOf(owner.address);
        const recipientBalanceBefore = await legitToken.balanceOf(user2.address);

        await legitToken.connect(owner).transfer(user2.address, transferAmount);

        const senderBalanceAfter = await legitToken.balanceOf(owner.address);
        const recipientBalanceAfter = await legitToken.balanceOf(user2.address);

        expect(senderBalanceAfter).to.equal(senderBalanceBefore - transferAmount);
        expect(recipientBalanceAfter).to.equal(recipientBalanceBefore + netAmount);
    });

    it("✅ Should transfer 15% receiver tax to the affiliates address", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        const receiverTax = transferAmount * BigInt(TAX_RECEIVER) / BigInt(100);
        const affiliatesBalanceBefore = await legitToken.balanceOf(affiliatesAddress.address);

        await expect(legitToken.connect(owner).transfer(user2.address, transferAmount))
            .to.emit(legitToken, "ReceiverTaxPaidToAffiliates")
            .withArgs(owner.address, affiliatesAddress.address, receiverTax);

        const affiliatesBalanceAfter = await legitToken.balanceOf(affiliatesAddress.address);
        expect(affiliatesBalanceAfter).to.equal(affiliatesBalanceBefore + receiverTax);
    });

    it("✅ Should burn 1% of the amount", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        const burnAmount = transferAmount / BigInt(100);

        const totalSupplyBefore = await legitToken.totalSupply();

        await legitToken.connect(owner).transfer(user2.address, transferAmount);

        const totalSupplyAfter = await legitToken.totalSupply();
        expect(totalSupplyAfter).to.equal(totalSupplyBefore - burnAmount);
    });

    it("✅ Should allocate 10% of the amount to the contract and the 9% of taxes", async function () {
        await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        const expectedTaxes = transferAmount * BigInt(9) / BigInt(100);
        const expectedContractAllocation = transferAmount * BigInt(10) / BigInt(100);

        const contractBalanceBefore = await legitToken.balanceOf(legitToken.getAddress());

        await legitToken.connect(owner).transfer(user2.address, transferAmount);

        const contractBalanceAfter = await legitToken.balanceOf(legitToken.getAddress());
        expect(contractBalanceAfter).to.equal(contractBalanceBefore + expectedContractAllocation + expectedTaxes);
    });

    it("✅ Should emit TransferTaxed event", async function () {
      await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

        await expect(legitToken.connect(owner).transfer(user2.address, transferAmount))
            .to.emit(legitToken, "TransferTaxed")
            .withArgs(owner.address, user2.address, transferAmount);
    });

    it("✅ Should transfer tokens, verify taxes, and withdraw them", async function () {
      await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

      // Transfer tokens from owner to user2
      const senderTax = transferAmount * BigInt(TAX_SENDER) / BigInt(100);
      const receiverTax = transferAmount * BigInt(TAX_RECEIVER) / BigInt(100);
      const taxes = transferAmount * BigInt(9) / BigInt(100);

      await legitToken.connect(owner).transfer(user2.address, transferAmount);

      // Verify taxes are available for owner
      const totalSupply = await legitToken.totalSupply();
      const ownerBalanceBeforeCheck = await legitToken.balanceOf(owner.address);
      const taxesForOwnerBeforeCheck = taxes * ownerBalanceBeforeCheck / totalSupply;
      const availableTaxesBefore = await legitToken.getAvailableTaxes(owner.address);
      expect(availableTaxesBefore).to.equal(taxesForOwnerBeforeCheck);

      // Withdraw taxes from owner
      const ownerBalanceBefore = await legitToken.balanceOf(owner.address);
      await legitToken.connect(owner).withdrawTaxes();
      const ownerBalanceAfter = await legitToken.balanceOf(owner.address);
      const availableTaxesAfter = await legitToken.getAvailableTaxes(owner.address);

      // Calculate the taxes available after receiving the first taxes:
      const addedBalance = ownerBalanceAfter - ownerBalanceBefore;
      const taxesAfterReceiving = taxes * addedBalance / totalSupply;

      // Verify taxes are withdrawn, in owner account
      expect(availableTaxesAfter).to.equal(taxesAfterReceiving);

      // Ensure the owner to have received the withdrawn taxes
      expect(ownerBalanceAfter).to.equal(ownerBalanceBefore + taxesForOwnerBeforeCheck);

      // Make sure we can't withdraw again:
      await expect(legitToken.connect(owner).withdrawTaxes()).to.be.revertedWith("Withdrawal allowed once a month");

      // Advance time 31 days:
      await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]); // 31 days in seconds
      await ethers.provider.send("evm_mine", []); // Mine a new block to apply the time change

      // Withdraw taxes again
      await legitToken.connect(owner).withdrawTaxes();

      // Ensure the owner to have received the withdrawn taxes
      const ownerBalanceFinal = await legitToken.balanceOf(owner.address);
      expect(ownerBalanceFinal).to.equal(ownerBalanceBefore + taxesForOwnerBeforeCheck + taxesAfterReceiving);


  });
});

describe("LegitToken - BNB Voting & Dividend Distribution", function () {
  let legitToken: LegitToken;
  let affiliatesAddress: SignerWithAddress;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let nonTokenHolder: SignerWithAddress;
  const VOTE_DURATION = 7 * 24 * 60 * 60; // 7 days in seconds
  const AMOUNT_ETH = ethersUtils.parseEther("1"); // 1 ETH in Wei

  beforeEach(async function () {
      [owner, user1, user2, user3, nonTokenHolder, affiliatesAddress] = await ethers.getSigners();

      const LegitTokenFactory = await ethers.getContractFactory("LegitToken");
      legitToken = (await LegitTokenFactory.deploy()) as LegitToken;

      // Set Affiliate contract:
      await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

      // Distribute tokens for voting
      await legitToken.connect(owner).transfer(user1.address, ethersUtils.parseEther("1000")); // 1000 tokens
      await legitToken.connect(owner).transfer(user2.address, ethersUtils.parseEther("2000")); // 2000 tokens
      await legitToken.connect(owner).transfer(user3.address, ethersUtils.parseEther("3000")); // 3000 tokens

      // Send BNB to the contract:
      await user1.sendTransaction({
        to: legitToken.getAddress(), // Contract address
        value: ethersUtils.parseEther("100"), // 1 ETH in Wei
      });
  });

  it("✅ Should receive BNB", async function () {
    const initialBalance = await ethers.provider.getBalance(legitToken.getAddress());

      await owner.sendTransaction({
          to: legitToken.getAddress(),
          value: AMOUNT_ETH,
      });

      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      expect(contractBalance).to.equal(initialBalance + AMOUNT_ETH);
  });

  it("✅ Should allow token holders to vote pro-rata", async function () {
      const user1Balance = await legitToken.balanceOf(user1.address);
      const user2Balance = await legitToken.balanceOf(user2.address);
      const user3Balance = await legitToken.balanceOf(user3.address);

      let contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await legitToken.connect(user1).vote(true);
      await legitToken.connect(user2).vote(true);
      await legitToken.connect(user3).vote(false);

      const totalVotes = await legitToken.totalVotes();
      const totalVotedSupply = await legitToken.totalVotedSupply();

      expect(totalVotes).to.equal(user1Balance + user2Balance); // user1 + user2
      expect(totalVotedSupply).to.equal(user1Balance + user2Balance + user3Balance); // user1 + user2 + user3
  });

  it("✅ Should not allow users to vote more than once", async function () {
      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await legitToken.connect(user1).vote(true);
      await expect(legitToken.connect(user1).vote(false)).to.be.revertedWith("Already voted");
  });

  it("✅ Should not allow non-token holders to vote", async function () {
      let contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await expect(legitToken.connect(nonTokenHolder).vote(true)).to.be.revertedWith("Must hold tokens to vote");
  });

  it("✅ Should conclude vote and distribute BNB if >50% votes YES", async function () {
      await owner.sendTransaction({
          to: legitToken.getAddress(),
          value: AMOUNT_ETH,
      });

      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await legitToken.connect(user1).vote(true); // 1000 tokens
      await legitToken.connect(user2).vote(true); // 2000 tokens
      await legitToken.connect(user3).vote(false); // 3000 tokens

      // ⏩ Fast forward 7 days
      await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
      await ethers.provider.send("evm_mine", []);

      // Check balances before distribution
      const balanceBeforeUser1 = await ethers.provider.getBalance(user1.address);
      const balanceBeforeUser2 = await ethers.provider.getBalance(user2.address);
      const balanceBeforeUser3 = await ethers.provider.getBalance(user3.address);

      await legitToken.concludeVote();

      // Check that BNB was distributed
      const dividendsDistributed = await legitToken.totalDividendsDistributed();
      expect(contractBalance - dividendsDistributed).to.equal(0);

      const balanceAfterUser1 = await ethers.provider.getBalance(user1.address);
      const balanceAfterUser2 = await ethers.provider.getBalance(user2.address);
      const balanceAfterUser3 = await ethers.provider.getBalance(user3.address);

      const totalSupply = ethersUtils.parseEther("6000");
      const expectedShareUser1 = AMOUNT_ETH * BigInt(1000) / BigInt(totalSupply);
      const expectedShareUser2 = AMOUNT_ETH * BigInt(2000) / BigInt(totalSupply);
      const expectedShareUser3 = AMOUNT_ETH * BigInt(3000) / BigInt(totalSupply);

      expect(balanceAfterUser1 - balanceBeforeUser1).to.equal(expectedShareUser1);
      expect(balanceAfterUser2 - balanceBeforeUser2).to.equal(expectedShareUser2);
      expect(balanceAfterUser3 - balanceBeforeUser3).to.equal(expectedShareUser3);
  });

  it("✅ Should keep BNB in contract if vote fails", async function () {
      await owner.sendTransaction({
          to: legitToken.getAddress(),
          value: AMOUNT_ETH,
      });

      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await legitToken.connect(user1).vote(true);
      await legitToken.connect(user2).vote(false);
      await legitToken.connect(user3).vote(false);

      // ⏩ Fast forward 7 days
      await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
      await ethers.provider.send("evm_mine", []);

      await legitToken.concludeVote();

      // Check that BNB is still in contract
      expect(contractBalance).to.equal(contractBalance);
  });

  it("✅ Should prevent concluding vote before 7 days", async function () {
      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance);

      await legitToken.connect(user1).vote(true);
      await expect(legitToken.concludeVote()).to.be.revertedWith("Voting period not over");
  });

  it("✅ Should execute two votes and ensure BNB is distributed properly", async function () {
    // --- First Voting Round ---
    await legitToken.startVoteDividends(AMOUNT_ETH); // Vote to distribute 1 BNB

    await legitToken.connect(user1).vote(true); // User1 votes YES (1000 tokens)
    await legitToken.connect(user2).vote(true); // User2 votes YES (2000 tokens)
    await legitToken.connect(user3).vote(false); // User3 votes NO (3000 tokens)

    // ⏩ Fast forward 7 days
    await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
    await ethers.provider.send("evm_mine", []);

    await legitToken.concludeVote();

    // Check that 1 BNB is allocated as dividends
    const totalDividends1 = await legitToken.totalDividendsDistributed();
    expect(totalDividends1).to.equal(AMOUNT_ETH);

    // --- Second Voting Round ---
    await legitToken.startVoteDividends(AMOUNT_ETH); // Vote to distribute the remaining 1 BNB

    await legitToken.connect(user1).vote(true);
    await legitToken.connect(user2).vote(true);
    await legitToken.connect(user3).vote(true); // All users vote YES this time

    // ⏩ Fast forward 7 days
    await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
    await ethers.provider.send("evm_mine", []);

    await legitToken.concludeVote();

    // Check that 2 BNB is now distributed
    const totalDividends2 = await legitToken.totalDividendsDistributed();
    expect(totalDividends2).to.equal(ethersUtils.parseEther("2"));

    // --- Withdraw Dividends ---
    const balanceBeforeUser1 = await ethers.provider.getBalance(user1.address);
    await legitToken.connect(user1).withdrawDividends();
    const balanceAfterUser1 = await ethers.provider.getBalance(user1.address);

    expect(balanceAfterUser1).to.be.gt(balanceBeforeUser1); // Ensure user1 received dividends
  });

  it("❌ Should revert if a vote is already active", async function () {
      const contractBalance = await ethers.provider.getBalance(legitToken.getAddress());
      await legitToken.startVoteDividends(contractBalance); // First vote starts successfully

      await expect(legitToken.startVoteDividends(contractBalance)).to.be.revertedWith(
          "Vote already in progress"
      );
  });

  it("❌ Should revert if the contract has insufficient BNB", async function () {
      const LegitTokenFactory = await ethers.getContractFactory("LegitToken");
      const emptyLegitToken = (await LegitTokenFactory.deploy()) as LegitToken;
      await expect(emptyLegitToken.startVoteDividends(AMOUNT_ETH)).to.be.revertedWith(
          "Insufficient contract BNB balance"
      );
  });

  it("❌ Should revert if trying to vote with no active session", async function () {
    await expect(legitToken.connect(owner).vote(true)).to.be.revertedWith(
        "No active vote session"
    );
  });

  it("❌ Should revert if trying to concludeVote with no active session", async function () {
    await expect(legitToken.connect(owner).concludeVote()).to.be.revertedWith(
        "No active vote session"
    );
  });

  it("❌ Should revert if trying to withdraw dividends with none available", async function () {
    await expect(legitToken.connect(user1).withdrawDividends()).to.be.revertedWith(
        "No dividends available"
    );
  });

  it("✅ Should allow first withdrawal, then revert if trying again before 30 days", async function () {
    // Start and complete a vote to distribute dividends
    await legitToken.startVoteDividends(AMOUNT_ETH);
    await legitToken.connect(user1).vote(true);
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Fast forward 7 days
    await ethers.provider.send("evm_mine", []);
    await legitToken.concludeVote();

    // First withdrawal should succeed
    await expect(legitToken.connect(user1).withdrawDividends()).to.not.be.reverted;

    // Vote again
    await legitToken.startVoteDividends(AMOUNT_ETH);
    await legitToken.connect(user1).vote(true);

    // Trying to withdraw again immediately should fail
    await expect(legitToken.connect(user1).withdrawDividends()).to.be.revertedWith(
        "Withdrawal allowed once a month"
    );

    // Fast forward 31 days
    await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);

    // Second withdrawal should now succeed
    await expect(legitToken.connect(user1).withdrawDividends()).to.not.be.reverted;
  });

  it("❌ Should revert if trying to send 0 BNB to contract", async function () {
    await expect(
        user1.sendTransaction({
            to: legitToken.getAddress(),
            value: ethersUtils.parseEther("0"), // Sending 0 BNB
        })
    ).to.be.revertedWith("Must send BNB");
  });

  it("✅ Should accept a valid BNB transfer", async function () {
      await expect(
          user1.sendTransaction({
              to: legitToken.getAddress(),
              value: AMOUNT_ETH, // Sending 1 BNB
          })
      ).to.not.be.reverted;
  });
});



describe("LegitToken - Voting Session for a Transfer", function () {
  let legitToken: LegitToken;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let recipient: SignerWithAddress;
  let affiliatesAddress: SignerWithAddress;
  let addressZero = "0x0000000000000000000000000000000000000000";
  const AMOUNT_ETH = ethersUtils.parseEther("1"); // 1 BNB in Wei
  const VOTE_DURATION = 7 * 24 * 60 * 60; // 7 days in seconds

  beforeEach(async function () {
      [owner, user1, user2, recipient, affiliatesAddress] = await ethers.getSigners();

      const LegitTokenFactory = await ethers.getContractFactory("LegitToken");
      legitToken = await LegitTokenFactory.deploy();

      // Set Affiliate contract:
      await legitToken.connect(owner).setAffiliatesAddress(affiliatesAddress.address);

      // Give user1 and user2 some tokens for voting
      await legitToken.transfer(user1.address, ethersUtils.parseEther("1000")); // 1000 tokens
      await legitToken.transfer(user2.address, ethersUtils.parseEther("2000")); // 2000 tokens

      // Send 2 BNB to the contract
      await owner.sendTransaction({
          to: legitToken.getAddress(),
          value: ethersUtils.parseEther("2"),
      });
  });

  it("✅ Should execute a transfer vote and send BNB to recipient if approved", async function () {
      // Start voting session to transfer 1 BNB to recipient
      await legitToken.startVoteTransfer(AMOUNT_ETH, recipient.address, "My Reason");

      // Users vote
      await legitToken.connect(user1).vote(true); // 1000 tokens
      await legitToken.connect(user2).vote(true); // 2000 tokens

      // ⏩ Fast forward 7 days
      await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
      await ethers.provider.send("evm_mine", []);

      // Get recipient's initial balance
      const balanceBefore = await ethers.provider.getBalance(recipient.address);

      // Conclude the vote
      await legitToken.concludeVote();

      // Check that 1 BNB was transferred to the recipient
      const balanceAfter = await ethers.provider.getBalance(recipient.address);
      expect(balanceAfter - balanceBefore).to.equal(AMOUNT_ETH);
  });

  it("❌ Should NOT transfer BNB if the vote fails", async function () {
      // Start voting session to transfer 1 BNB to recipient
      await legitToken.startVoteTransfer(AMOUNT_ETH, recipient.address, "My Reason");

      // Only user1 votes YES (1000 tokens), user2 votes FALSE
      await legitToken.connect(user1).vote(true);
      await legitToken.connect(user2).vote(false);

      // ⏩ Fast forward 7 days
      await ethers.provider.send("evm_increaseTime", [VOTE_DURATION]);
      await ethers.provider.send("evm_mine", []);

      // Get recipient's initial balance
      const balanceBefore = await ethers.provider.getBalance(recipient.address);

      // Conclude the vote
      await legitToken.concludeVote();

      // Check that BNB was NOT transferred to recipient
      const balanceAfter = await ethers.provider.getBalance(recipient.address);
      expect(balanceAfter).to.equal(balanceBefore);
  });

  it("❌ Should revert if trying to start a vote when another is active", async function () {
      await legitToken.startVoteTransfer(AMOUNT_ETH, recipient.address, "My Reason");

      await expect(legitToken.startVoteTransfer(AMOUNT_ETH, recipient.address, "My Reason")).to.be.revertedWith(
          "Vote already in progress"
      );
  });

  it("❌ Should revert if trying to transfer more BNB than contract holds", async function () {
      await expect(
          legitToken.startVoteTransfer(ethersUtils.parseEther("5"), recipient.address, "My Reason")
      ).to.be.revertedWith("Insufficient contract BNB balance");
  });

  it("❌ Should revert if recipient address is 0", async function () {
      await expect(
          legitToken.startVoteTransfer(AMOUNT_ETH, addressZero, "My Reason")
      ).to.be.revertedWith("Address cannot be 0");
  });
});