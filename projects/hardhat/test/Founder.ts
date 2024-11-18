import { expect } from "chai";
import { ethers } from "hardhat";
import { ethers as ethersUtils } from "ethers";
import { Founder, ERC20Mock } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Founder Contract", function () {
    let founder: Founder;
    let currencyToken: ERC20Mock;
    let owner: SignerWithAddress, holder1: SignerWithAddress, holder2: SignerWithAddress, holder3: SignerWithAddress, nonHolder: SignerWithAddress;
    let ownerAddress: string, holder1Address: string, holder2Address: string, holder3Address: string, nonHolderAddress: string;

    beforeEach(async function () {
        [owner, holder1, holder2, holder3, nonHolder] = await ethers.getSigners();
        [ownerAddress, holder1Address, holder2Address, holder3Address, nonHolderAddress] = await Promise.all(
            [owner, holder1, holder2, holder3, nonHolder].map((signer) => signer.getAddress())
        );

        // Deploy a mock ERC20 token to act as currencyToken
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        currencyToken = await ERC20Mock.deploy("Mock Token", "MTKN", 18);

        // Mint some tokens to the contract for testing dividends
        await currencyToken.mint(ownerAddress, ethersUtils.parseEther("1000"));

        // Deploy the Founder contract
        const Founder = await ethers.getContractFactory("Founder");
        founder = await Founder.deploy([holder1Address, holder2Address, holder3Address]);

        // Transfer some ERC20 tokens to the Founder contract for dividends
        await currencyToken.transfer(founder.target, ethersUtils.parseEther("500"));
    });

    it("should revert if the provided address is zero", async () => {
        await expect(founder.connect(owner).setCurrencyAddress("0x0000000000000000000000000000000000000000"))
          .to.be.revertedWith("Invalid address");
    });

    it("should revert if currency total supply is 0", async () => {
        // Deploy a mock ERC20 token to act as currencyToken
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        currencyToken = await ERC20Mock.deploy("Mock Token", "MTKN", 0);

        // Deploy the Founder contract
        const Founder = await ethers.getContractFactory("Founder");
        founder = await Founder.deploy([holder1Address, holder2Address, holder3Address]);

        await expect(founder.connect(owner).setCurrencyAddress(currencyToken.target))
          .to.be.revertedWith("Provided Currency ERC20 contract should not have a total supply of 0");
    });

    it("Should initialize holders with the correct balances", async function () {
        const balanceHolder1 = await founder.balanceOf(holder1Address);
        expect(balanceHolder1).to.equal(ethersUtils.parseEther("10000000"));

        const balanceHolder2 = await founder.balanceOf(holder2Address);
        expect(balanceHolder2).to.equal(ethersUtils.parseEther("10000000"));
    });

    it("Should allow the owner to set the currency address", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);
        expect(await founder.currencyAddress()).to.equal(currencyToken.target);
    });

    it("Should not allow setting the currency address more than once", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);
        await expect(founder.connect(owner).setCurrencyAddress(currencyToken.target)).to.be.revertedWith(
            "Currency Address already set"
        );
    });

    it("Should compute available dividends correctly", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);
        const dividends = await founder.getAvailableDividends(holder1Address);
        expect(dividends).to.be.gt(0);
    });

    it("Should allow holders to withdraw dividends", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);
        const availableDividends = await founder.getAvailableDividends(holder1Address);

        await founder.connect(holder1).withdrawDividends(availableDividends);

        const withdrawnDividends = await founder.withdrawnDividends(holder1Address);
        expect(withdrawnDividends).to.equal(availableDividends);
    });

    it("Should proportionally withdraw dividends on transfer", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        const initialDividends = await founder.getAvailableDividends(holder1Address);

        await founder.connect(holder1).transfer(holder2Address, ethersUtils.parseEther("5000000"));

        const remainingDividends = await founder.getAvailableDividends(holder1Address);
        expect(remainingDividends).to.be.lt(initialDividends);
    });

    it("Should emit TransferExecuted on token transfer", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        // calculate the dividends:
        const senderDividends = await founder.connect(holder1).getAvailableDividends(holder2Address);
        const senderBalance = await founder.connect(holder1).balanceOf(holder2Address);
        const amount = ethersUtils.parseEther("5000000");
        const expectedDividends = (senderDividends * amount) / senderBalance;

        await expect(founder.connect(holder1).transfer(holder2Address, amount))
            .to.emit(founder, "TransferExecuted")
            .withArgs(holder1Address, holder2Address, amount, expectedDividends);
    });

    it("Should reject dividend withdrawal if no dividends are available", async function () {
        // Deploy a mock ERC20 token to act as currencyToken
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        currencyToken = await ERC20Mock.deploy("Mock Token", "MTKN", 18);

        // Deploy the Founder contract
        const Founder = await ethers.getContractFactory("Founder");
        founder = await Founder.deploy([holder1Address, holder2Address, holder3Address]);

        // Set the currency contract:
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        // withdraw dividends:
        await expect(founder.connect(nonHolder).withdrawDividends(ethersUtils.parseEther("1"))).to.be.revertedWith(
            "No dividends available"
        );
    });

    it("Should reject dividend withdrawal if amount is 0", async function () {
        // withdraw dividends:
        await expect(founder.connect(nonHolder).withdrawDividends(ethersUtils.parseEther("0"))).to.be.revertedWith(
            "Amount cannot be 0"
        );
    });

    it("Should change amount if requested amount is greater than available dividends", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        // fetch the amount of dividends:
        const senderDividends = await founder.connect(holder1).getAvailableDividends(holder1);

        // withdraw dividends:
        await expect(founder.connect(holder1).withdrawDividends(senderDividends + ethersUtils.parseEther("1")))
            .to.emit(founder, "WithdrawDividends")
            .withArgs(holder1, senderDividends);
    });

    it("Should fail if currency address is not set when calculating total dividends", async function () {
        await expect(founder.totalDividends()).to.be.revertedWith("Currency Address not set");
    });

    it("Should return 0 if totalDividends is 0", async function () {
        // Deploy a mock ERC20 token to act as currencyToken
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        currencyToken = await ERC20Mock.deploy("Mock Token", "MTKN", 18);

        // Deploy the Founder contract
        const Founder = await ethers.getContractFactory("Founder");
        founder = await Founder.deploy([holder1Address, holder2Address, holder3Address]);

        // Ensure currency address is set
        await founder.setCurrencyAddress(currencyToken.target);

        const totalDividendsAvailable = await founder.connect(holder1).totalDividendsAvailable();
        expect(totalDividendsAvailable).to.equal(0);
    });

    it("Should return totalDividends minus totalWithdrawnDividends", async function () {
        // Set currency address
        await founder.setCurrencyAddress(currencyToken.target);

        // Withdraw some dividends
        await founder.connect(holder1).withdrawDividends(ethersUtils.parseEther("100"));

        const totalDividends = await founder.connect(holder1).totalDividends();
        const totalWithdrawnDividends = await founder.connect(holder1).totalWithdrawnDividends();
        const expectedAvailable = totalDividends - (totalWithdrawnDividends);

        const totalDividendsAvailable = await founder.connect(holder1).totalDividendsAvailable();
        expect(totalDividendsAvailable).to.equal(expectedAvailable);
    });

    it("Should calculate correctly when totalDividends is greater than totalWithdrawnDividends", async function () {
        // Set currency address
        await founder.setCurrencyAddress(currencyToken.target);

        // Ensure some tokens are withdrawn
        await founder.connect(holder1).withdrawDividends(ethersUtils.parseEther("50"));

        const totalDividends = await founder.connect(holder1).totalDividends();
        const totalWithdrawnDividends = await founder.connect(holder1).totalWithdrawnDividends();
        const expectedAvailable = totalDividends - (totalWithdrawnDividends);

        const totalDividendsAvailable = await founder.connect(holder1).totalDividendsAvailable();
        expect(totalDividendsAvailable).to.equal(expectedAvailable);
    });

    it("Should revert if currency address is not set", async function () {
        // Deploy the Founder contract
        const Founder = await ethers.getContractFactory("Founder");
        founder = await Founder.deploy([holder1Address, holder2Address, holder3Address]);

        await expect(founder.totalDividendsAvailable()).to.be.revertedWith("Currency Address not set");
    });

    it("Should revert if transfer is bigger than available funds", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        // fetch available funds:
        const availableFunds = await founder.connect(owner).balanceOf(owner);

        await expect(founder.connect(owner).transfer(holder2Address, availableFunds + ethersUtils.parseEther("1")))
            .to.revertedWith("Insufficient funds");
    });

    it("Should not change dividend is transfer withtout dividends available", async function () {
        await founder.connect(owner).setCurrencyAddress(currencyToken.target);

        // fetch available funds:
        const availableFunds = await founder.connect(owner).balanceOf(owner);

        // fetch available dividends
        const availableDividends = await founder.connect(holder1).getAvailableDividends(holder1);

        // withdraw the dividends:
        await founder.connect(holder1).withdrawDividends(availableDividends);

        // dividends should be zero:
        expect(await founder.connect(holder1).getAvailableDividends(holder1)).to.be.eq(0);

        await expect(founder.connect(holder1).transfer(holder2Address, availableFunds))
            .to.not.reverted;

        // dividends should be zero:
        expect(await founder.connect(holder1).getAvailableDividends(holder1)).to.be.eq(0);
    });
});