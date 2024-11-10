import { expect } from "chai";
import { ethers } from "hardhat";
import { ethers as ethersUtils } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { CurrencyFounder } from "../typechain-types";
import { NonPayableMock } from "../typechain-types";
import { MaliciousCurrencyFounderMock } from "../typechain-types";

describe("CurrencyFounder", function () {
  let currencyFounder: CurrencyFounder;
  let deployer: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let nonPayableMock: NonPayableMock;
  let malicious: MaliciousCurrencyFounderMock;

  function bigIntToHexString(value: bigint): string {
    return '0x' + value.toString(16);
  }

  async function impersonateAddress(address: string, amount: string): Promise<SignerWithAddress> {
    // Enable impersonation for the specified address
    await ethers.provider.send("hardhat_impersonateAccount", [address]);

    // Fund the impersonated account with Ether
    await ethers.provider.send("hardhat_setBalance", [
        address,
        bigIntToHexString(ethersUtils.parseEther(amount)), // Set balance to the specified amount in Ether
    ]);
  
    // Get the impersonated signer
    const signer = await ethers.getSigner(address);
    return signer as SignerWithAddress;
  }

  beforeEach(async function () {
    [deployer, account1, account2] = await ethers.getSigners();

    // Deploy the contract using the deployer
    const CurrencyFounderFactory = await ethers.getContractFactory("CurrencyFounder", deployer);
    currencyFounder = (await CurrencyFounderFactory.deploy()) as CurrencyFounder;

    // Deploy the mock contract
    const NonPayableMockFactory = await ethers.getContractFactory("NonPayableMock", deployer);
    nonPayableMock = await NonPayableMockFactory.deploy() as NonPayableMock;

    // Deploy the Malicious mock contract
    const MaliciousFactory = await ethers.getContractFactory("MaliciousCurrencyFounderMock", deployer);
    malicious = (await MaliciousFactory.deploy(currencyFounder.getAddress())) as MaliciousCurrencyFounderMock;
  });

  it("should mint the initial token distribution correctly", async function () {
    const balance1 = await currencyFounder.balanceOf("0xb2BB6301216bCe25128123EE22A23847fa80Cde7");
    expect(balance1).to.equal(ethersUtils.parseUnits("2500000", 18));

    const balance2 = await currencyFounder.balanceOf("0x20343F2CeBf5895c5d5707B25d0c3f526816F4dc");
    expect(balance2).to.equal(ethersUtils.parseUnits("2500000", 18));

    const balance3 = await currencyFounder.balanceOf("0x5a9eD1f68865A4719a4F3928EdB2c1BbbA8655c4");
    expect(balance3).to.equal(ethersUtils.parseUnits("47500000", 18));

    const balance4 = await currencyFounder.balanceOf("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC");
    expect(balance4).to.equal(ethersUtils.parseUnits("47500000", 18));
  });

  it("should accept BNB and record dividends", async function () {
    const amount = ethersUtils.parseEther("1.0");
    await account1.sendTransaction({
      to: currencyFounder.getAddress(),
      value: amount,
    });

    const totalDividends = await currencyFounder.totalDividends();
    expect(totalDividends).to.equal(amount);
  });

  it("should calculate dividends for an account correctly", async function () {
    const amount = ethersUtils.parseEther("2.0");
    await deployer.sendTransaction({
      to: currencyFounder.getAddress(),
      value: amount,
    });

    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
    const dividendForSpecificHolder = await currencyFounder.getDividendAmount(specificHolder.address);
    expect(dividendForSpecificHolder).to.be.gt(0);
  });

  it("should allow an account to withdraw dividends", async function () {
    const amount = ethersUtils.parseEther("3.0");
    await deployer.sendTransaction({
      to: currencyFounder.getAddress(),
      value: amount,
    });

    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
    const initialBalance = await ethers.provider.getBalance(account1.address);

    await currencyFounder.connect(specificHolder).transfer(account1.address, ethersUtils.parseUnits("10000000", 18));
    await currencyFounder.connect(account1).withdrawDividend(account1.address, ethersUtils.parseEther("0.5"));

    const finalBalance = await ethers.provider.getBalance(account1.address);
    expect(finalBalance).to.be.gt(initialBalance);
  });

  it("should transfer dividends when units are transfered", async function () {
    const amount = ethersUtils.parseEther("1.0");
    await deployer.sendTransaction({
      to: currencyFounder.getAddress(),
      value: amount,
    });

    // withdraw half of its dividends:
    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
    const specificHolderInitialBalance = await ethers.provider.getBalance(specificHolder.address);
    const specificHolderDividends = await currencyFounder.getDividendAmount(specificHolder.address);
    const specificHolderHalfDividends = specificHolderDividends / BigInt(2);
    await currencyFounder.connect(specificHolder).withdrawDividend(specificHolder.address, specificHolderHalfDividends);
    const specificHolderAfterDividendFirstPayout = await currencyFounder.getDividendAmount(specificHolder.address);

    // transfer half of our tokens:
    const balance = await currencyFounder.balanceOf(specificHolder);
    const halfBalance = balance / BigInt(2);
    await currencyFounder.connect(specificHolder).transfer(account1.address, halfBalance);

    // fetch the available dividends:
    const dividendsAfterHalfTransfer = await currencyFounder.getDividendAmount(specificHolder.address);
    expect(dividendsAfterHalfTransfer).to.be.eq(specificHolderAfterDividendFirstPayout / BigInt(2));
  });

  it("should not allow dividend withdrawal greater than available amount", async function () {
    const amount = ethersUtils.parseEther("1.0");
    await deployer.sendTransaction({
      to: currencyFounder.getAddress(),
      value: amount,
    });

    await expect(
      currencyFounder.connect(account2).withdrawDividend(account2.address, ethersUtils.parseEther("10.0"))
    ).to.be.revertedWith("No dividend for that address");
  });

  it("should revert when withdraw dividend amount is zero", async function () {
    await expect(
      currencyFounder.connect(account2).withdrawDividend(account2.address, ethersUtils.parseEther("0"))
    ).to.be.revertedWith("Amount must be greater than zero");
  });

  it("should revert transfer if balance is insufficient", async function () {
    await expect(
      currencyFounder.connect(account1).transfer(account2.address, ethersUtils.parseUnits("5000", 18))
    ).to.be.revertedWithCustomError;
  });

  it("should revert when sending zero value to the contract", async function () {
    await expect(
      deployer.sendTransaction({
        to: currencyFounder.getAddress(),
        value: ethersUtils.parseEther("0"),
      })
    ).to.be.revertedWith("Send BNB to deposit payment");
  });

  it("should correctly adjust dividends on transfer when sender has withdrawn dividends", async function () {
    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
  
    // Send initial payment and withdraw a part
    await deployer.sendTransaction({ to: currencyFounder.getAddress(), value: ethersUtils.parseEther("5.0") });
    await currencyFounder.connect(specificHolder).withdrawDividend(specificHolder.address, ethersUtils.parseEther("1.0"));
  
    // Transfer half of the tokens
    const balance = await currencyFounder.balanceOf(specificHolder.address);
    await currencyFounder.connect(specificHolder).transfer(account1.address, balance / BigInt(2));
  
    // Check if the `accountsDividendsWithdrawn` is adjusted correctly
    const remainingDividends = await currencyFounder.getDividendAmount(specificHolder.address);
    expect(remainingDividends).to.be.lt(ethersUtils.parseEther("4.0"));
  });

  it("should revert when withdrawing dividends with zero token balance", async function () {
    await expect(
      currencyFounder.connect(account2).withdrawDividend(account2.address, ethersUtils.parseEther("0.5"))
    ).to.be.revertedWith("No dividend for that address");
  });

  it("should revert if native value transfer fails during dividend withdrawal", async function () {
    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
    await deployer.sendTransaction({ to: currencyFounder.getAddress(), value: ethersUtils.parseEther("5.0") });

    await expect(
        currencyFounder.connect(specificHolder).withdrawDividend(nonPayableMock.getAddress(), ethersUtils.parseEther("0.0001"))
    ).to.be.revertedWith("Transfer failed");
  });

  it("should prevent reentrancy during withdrawDividend", async function () {
    // send tokens to the malicious contract:
    const specificHolder = await impersonateAddress("0x13B7fD960C3c105c0a80f05a2430783345A7c8dC", "2.0");
    const balance = await currencyFounder.balanceOf(specificHolder.address);
    await currencyFounder.connect(specificHolder).transfer(malicious.getAddress(), balance);

    // transfer payment:
    await deployer.sendTransaction({ to: currencyFounder.getAddress(), value: ethersUtils.parseEther("5.0") });

    // execute the attack:
    await expect(malicious.attack()).to.be.revertedWith("Transfer failed");
  });
});