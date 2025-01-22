// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LegitToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant TAX_SENDER = 20; // 20% sender tax
    uint256 public constant TAX_RECEIVER = 15; // 15% receiver tax
    uint256 public totalTaxesDistributed;

    mapping(address => uint256) public withdrawnTaxes;
    mapping(address => uint256) public totalEarnedTaxes;
    mapping(address => uint256) public lastTaxesWithdrawalTime; // Track last taxes withdrawal time

    // Voting system
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => uint256)) public votes;
    uint256 voteAmount;
    address voteAddress;
    string voteReason;
    uint256 votingSession;
    uint256 public totalVotes;
    uint256 public totalVotedSupply;
    uint256 public totalDividendsDistributed;
    mapping(address => uint256) public lastDividendsWithdrawalTime; // Track last dividends withdrawal time

    mapping(address => uint256) public withdrawnDividends;
    bool public voteActive;
    uint256 public voteEndTime;
    uint256 public constant VOTE_DURATION = 7 days; // Voting lasts for 7 days

    address public affiliatesAddress;

    event WithdrawTaxes(address recipient, uint256 amount);
    event WithdrawDividends(address recipient, uint256 amount);
    event TransferTaxed(address indexed sender, address indexed recipient, uint256 amount);
    event TransferDividends(uint256 totalBNB);
    event AffiliatesAddressSet(address indexed affiliatesAddress);
    event TaxesDistributed(uint256 amount);
    event ReceiverTaxPaidToAffiliates(address indexed sender, address indexed affiliates, uint256 amount);
    event BNBReceived(address sender, uint256 amount);
    event VoteStartedDividends(uint256 endTime, uint256 amount);
    event VoteStartedTransfer(uint256 endTime, uint256 amount, address toAddress, string reason);
    event Voted(address voter, uint256 weight);

    constructor() ERC20("Legit", "LEGIT") Ownable(msg.sender) {
        _mint(address(this), 38705880413439640000000000); // Mint 80M tokens to contract
        _mint(msg.sender, 3441912692820620000000000); // Mint deployer's tokens
        initialMint();
    }

    function tokenURI() external pure returns (string memory) {
        return "https://legitdao.com/contracts/legittoken.json";
    }

    /** 
     * @dev Set the Affiliates address, only once.
     */
    function setAffiliatesAddress(address _affiliatesAddress) public onlyOwner {
        require(affiliatesAddress == address(0), "Affiliates address already set");
        require(_affiliatesAddress != address(0), "Invalid address");
        affiliatesAddress = _affiliatesAddress;
        emit AffiliatesAddressSet(affiliatesAddress);
    }

    /** 
     * @dev Allows the contract to receive BNB.
     */
    receive() external payable {
        require(msg.value > 0, "Must send BNB");
        emit BNBReceived(msg.sender, msg.value);
    }

    /**
     * @dev Starts a vote to distribute the BNB in the contract.
     */
    function startVoteDividends(uint256 _voteAmount) external {
        require(!voteActive, "Vote already in progress");
        require(address(this).balance >= _voteAmount, "Insufficient contract BNB balance");

        voteActive = true;
        voteEndTime = block.timestamp + VOTE_DURATION;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = _voteAmount;

        emit VoteStartedDividends(voteEndTime, _voteAmount);
    }

    /**
     * @dev Starts a vote to transfer the BNB from a contract to another address
     */
    function startVoteTransfer(uint256 _voteAmount, address _toAddress, string memory _reason) external {
        require(!voteActive, "Vote already in progress");
        require(address(this).balance >= _voteAmount, "Insufficient contract BNB balance");
        require(_toAddress != address(0), "Address cannot be 0");

        voteActive = true;
        voteEndTime = block.timestamp + VOTE_DURATION;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = _voteAmount;
        voteAddress = _toAddress;
        voteReason = _reason;

        emit VoteStartedTransfer(voteEndTime, _voteAmount, _toAddress, _reason);
    }

    /**
     * @dev Allows token holders to vote pro-rata to their holdings.
     */
    function vote(bool approve) external {
        require(voteActive, "No active vote session");
        require(!hasVoted[msg.sender][votingSession], "Already voted");

        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance > 0, "Must hold tokens to vote");

        totalVotedSupply += userBalance;

        if (approve) {
            votes[msg.sender][votingSession] = userBalance;
            totalVotes += userBalance;
        }

        hasVoted[msg.sender][votingSession] = true;
        emit Voted(msg.sender, userBalance);
    }

    /**
     * @dev Concludes the vote and distributes BNB if approved.
     */
    function concludeVote() external {
        require(voteActive, "No active vote session");
        require(block.timestamp >= voteEndTime, "Voting period not over");

        voteActive = false;

        // If at least 50% of voting power approves, distribute BNB as dividends
        if (totalVotes * 2 >= totalVotedSupply) {
            if (voteAddress != address(0)) {
                (bool success, ) = voteAddress.call{value: voteAmount}("");
                require(success, "BNB transfer failed");
            } else {
                totalDividendsDistributed += voteAmount;
            }
            
            emit TransferDividends(voteAmount);
        }

        // Reset vote data
        votingSession++;
        totalVotes = 0;
        totalVotedSupply = 0;
        voteAmount = 0;
        voteAddress = address(0);
        voteReason = "";
    }

    /** 
     * @dev Calculate available dividends for an account.
     */
    function getAvailableDividends(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = address(account).balance;
        uint256 dividends = (totalDividendsDistributed * accountBalance) / totalSupply;
        if (dividends <= withdrawnDividends[account]) {
            return 0;
        }

        return dividends - withdrawnDividends[account];
    }

    /**
     * @dev Withdraw dividends in LegitToken, limited to once every 30 days.
     */
    function withdrawDividends() public nonReentrant {
        uint256 available = getAvailableDividends(msg.sender);
        require(available > 0, "No dividends available");

        uint256 lastWithdrawal = lastDividendsWithdrawalTime[msg.sender];
        require(block.timestamp >= lastWithdrawal + 30 days, "Withdrawal allowed once a month");

        withdrawnDividends[msg.sender] += available;
        lastDividendsWithdrawalTime[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: available}("");
        require(success, "BNB transfer failed");

        emit WithdrawDividends(msg.sender, available);
    }

    /** 
     * @dev Calculate available taxes for an account.
     */
    function getAvailableTaxes(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 accountBalance = balanceOf(account);
        uint256 taxes = (totalTaxesDistributed * accountBalance) / totalSupply;
        if (taxes <= withdrawnTaxes[account]) {
            return 0;
        }

        return taxes - withdrawnTaxes[account];
    }

    /**
     * @dev Withdraw taxes in LegitToken, limited to once every 30 days.
     */
    function withdrawTaxes() public nonReentrant {
        uint256 available = getAvailableTaxes(msg.sender);
        require(available > 0, "No taxes available");

        uint256 lastWithdrawal = lastTaxesWithdrawalTime[msg.sender];
        require(block.timestamp >= lastWithdrawal + 30 days, "Withdrawal allowed once a month");

        withdrawnTaxes[msg.sender] += available;
        lastTaxesWithdrawalTime[msg.sender] = block.timestamp;

        _transfer(address(this), msg.sender, available);
        emit WithdrawTaxes(msg.sender, available);
    }

    /**
     * @dev Override transfer to include taxation and tax allocations.
     */
    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(affiliatesAddress != address(0), "Affiliates address is required");

        // If sender is the affiliates contract or the contract itself, transfer without tax
        if (msg.sender == affiliatesAddress) {
            bool trxSuccess = super.transfer(recipient, amount);
            require(trxSuccess, "Transfer failed");

            emit TransferTaxed(msg.sender, recipient, amount);
            return trxSuccess;
        }

        // Apply taxes only if sender is NOT the affiliates contract
        uint256 senderTax = (amount * TAX_SENDER) / 100; // 20% sender tax
        uint256 receiverTax = (amount * TAX_RECEIVER) / 100; // 15% receiver tax
        uint256 netAmount = amount - (senderTax + receiverTax);

        uint256 taxes = (amount * 9) / 100; // 9% to taxes
        uint256 contractAllocation = (amount * 10) / 100; // 10% to contract
        uint256 burnAmount = (amount * 1) / 100; // 1% burned

        // Allocate taxes
        totalTaxesDistributed += taxes;
        emit TaxesDistributed(taxes);

        // Burn tokens
        _burn(msg.sender, burnAmount);

        // Transfer sender tax allocation to contract
        _transfer(msg.sender, address(this), contractAllocation + taxes);

        // Transfer receiver tax to affiliates
        _transfer(msg.sender, affiliatesAddress, receiverTax);
        emit ReceiverTaxPaidToAffiliates(msg.sender, affiliatesAddress, receiverTax);

        // Perform actual transfer
        bool success = super.transfer(recipient, netAmount);
        require(success, "Transfer failed");

        emit TransferTaxed(msg.sender, recipient, amount);
        return success;
    }

    function initialMint() private {
        _mint(0x93d957E733D03bC2809e7525b19Ecb320D4b95ff, 36093411200000000000000);
        _mint(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 231778299438400000000000);
        _mint(0xA28E98B686096AC65474a27e9b3A80e4072E613f, 69765498000000000000000);
        _mint(0x2009D4cffE6Ef87ea0019FeF3EdC62Ffd211731D, 12237269000000000000000);
        _mint(0xE5756aA82A39d3E23Dbc4831A8c6a6840b1663C2, 12890504000000000000000);
        _mint(0x85DCfd9D342232e008C13eA3eF47D3532115A92a, 4898391520000000000000);
        _mint(0x91C62Ff6e40b9718Af781148fac9D3B6684a4c24, 460713580800000000000000);
        _mint(0xf2869C98fB3D1753346449B06c18F27dc6611292, 32999690240000000000000);
        _mint(0xEe48960e29c896a4726A17Ec65A9dD39555476B0, 240251123200000000000000);
        _mint(0xB900548E21B6cbb11f578FCA70DFB80CFBEb29d5, 31407538800000000000000);
        _mint(0x6890eEf74Ea683a9383B6A32099b3967EAe7907E, 241243866204000000000000);
        _mint(0xF4245A2ca2faA8F21DbDA9aaF8213b45a8fF008c, 244745380000000000000000);
        _mint(0xb2f44b1A4f1CA5c7333151D8a730Af6Ac71ECd63, 22092407700000000000000);
        _mint(0x2E797DB6a3c9857dd7E32dB7Abb18D1bc919Fe53, 28616918880000000000000);
        _mint(0xa6E9ce90646c5624C7Cd530422EAA3A6662f1992, 20903520000000000000000);
        _mint(0x41E0d6fD4F722F39b3168E2CAC4da2E0a2B8fE6B, 25781008000000000000000);
        _mint(0xE67d86886f97daF5F059e876A4c3C04a514B3e69, 3915926080000000000000);
        _mint(0x1D446853cb843c890895cc86b94204C44FDFc2B6, 25781008000000000000000);
        _mint(0x941bbd3d449Cd092781f6f12819DaBD537c36947, 51396529800000000000000);
        _mint(0x449B3B54c81883680e09F2197838c4d99E1D02Ad, 20903520000000000000000);
        _mint(0x365d913C0a29D709FE3e649A1376951661b96FD1, 232551660000000000000000);
        _mint(0x2069fE5c5bEAf44DB81AED0a281512e40d3F809b, 25781008000000000000000);
        _mint(0xA3ec1aC881f6397d7AC0916c91013A159b2Fa9A7, 52593256320000000000000);
        _mint(0xfb50EFfC86D5bAe52DD18578d9A0c26Be5C0E8C2, 277389710400000000000000);
        _mint(0x61178ed786321F6acdF01633E336D94Fc42ec53A, 23255166000000000000000);
        _mint(0xEEc9AED9D7d5430DbEe4f6425c5974a6Dce5dD78, 20903520000000000000000);
        _mint(0x632d80122AD73dC56CF7429dD038B514C25F32b3, 65347016460000000000000);
        _mint(0xC555Acf73A1164f7F2eEe5E7F59FEE502F17AFec, 225758016000000000000000);
        _mint(0x0850A184714490B7EF2204c83e69532080F4845f, 2578100800000000000000);
        _mint(0xCFc8Be6e4Ff4e75ca8C95ed1a7Efc4eA8D894d0f, 94648525620000000000000);
        _mint(0x0441Fd8f6b6A9FeE71015F5E90a564Bf79d39052, 5348688180000000000000);
        _mint(0x96BAd93F26C64E72F7B22e3Dee731CA51e84c78b, 9667442510000000000000);
        _mint(0x04559347C9c78805CB65f6b290c0F6FB9FD2C3fD, 51562016000000000000000);
        _mint(0xc96eC4dBF43aB7723c1141B327302b0067881f3F, 209035200000000000000000);
        _mint(0xc691c060ebEeaB5655cC997246A962E7162e1e8e, 50907039040000000000000);
        _mint(0x29CBccD01D8d2d3A4f4C437c4Ae5039362DF95e2, 288364058400000000000000);
        _mint(0x621Cb7f95cd54B6884CA331CFb5e610Fa5Cb092d, 213714975540000000000000);
        _mint(0x43ddC99e9BaF04b12979b1ecc9272A0585b27c90, 146507545800000000000000);
        _mint(0x5F4113BFCD43307d2382D968327231351b58A5E4, 299059692800000000000000);
        _mint(0x8c5a840B5a9C2D78f665C93C63c3061F187C3346, 122372690000000000000000);
        _mint(0x63fAFE750b2bA064099195a0c01AB52880520d5D, 257810080000000000000000);
        _mint(0xa4BB241C53eAA799071E6Ad7b716DbA89A441f69, 254535195200000000000000);
        _mint(0x415625003693F35ab608Bc040600c9A5BAd994B8, 23255166000000000000000);
        _mint(0x2f5B28Dd625Ca194894165EDAA4704eE75d4E4AB, 339303845417020000000000);
        _mint(0x5620Df18BaA8fB97E809f05b3D59f9641C964ED0, 45859187352000000000000);
        _mint(0x6782F058b8Cc66625c9dA50137cC71730bde1c08, 232551660000000000000000);
        _mint(0x14E989718C622E6A90531C515BF2C9ac5Fb8d713, 164310377000000000000000);
        _mint(0xD2CB8B857b1AAbE1f4d7404eBe260CCa0862370D, 9302066400000000000000);
        _mint(0x13dA579450B27523006531Dfcf8bB63500E4f871, 244745380000000000000000);
        _mint(0x172aa24dCAEFcB2Ef14104761d37233ca6E6c166, 232551660000000000000000);
        _mint(0xeD45A63726EBdB50573C8dee4e961FdBF20e0e4a, 244745380000000000000000);
        _mint(0xe8b9F63bb91ed1a2ab7d8A5073a5FAf45c63340F, 17132176600000000000000);
        _mint(0xe6EfE00342D70cB85BE60AB796Ab98cC2a71f23B, 239605727020000000000000);
        _mint(0x81b01fD31017db4A6D85C098C26902Ba15E29625, 244745380000000000000000);
        _mint(0xCee382F4fF237942366a811D9ED596850E46A050, 20621426997600000000000);
        _mint(0x89CbF332571F54E2D1CEAdDC2B91b6A96f21df00, 129555145568860000000000);
        _mint(0xF92e87D99190a1bAB182c2F1014738F58f58a3E5, 27411482560000000000000);
        _mint(0x4877f396950C4c93DCF29AB78F5a246548AAf40E, 232551660000000000000000);
        _mint(0x283Aaf54D6e4d0FA42b358A098597E4Ba3f346e1, 267836801760000000000000);
        _mint(0xc4cE1C95F0ed3aE7F1428712C1E768CEF2462eC2, 257810080000000000000000);
        _mint(0x312FC133481fDc7d08a1EcdB1EE3f0208cDeBc39, 48949076000000000000000);
        _mint(0xEF98C81BD01bc0287d6ABbA8ad3d9496D93dEd76, 209035200000000000000000);
        _mint(0x7946c0c8807b8458f32DCF6aad0ad6807907e6C5, 254974169120000000000000);
        _mint(0x21FB0f62ADbf72fb7b515552DfC4B243AEF5439c, 257810080000000000000000);
        _mint(0x8c9a61A81863744A3C778f497F2853C9eE2C9D50, 70976160200000000000000);
        _mint(0x3a59Dbb440DcB76b37C67c2891679270C5909E51, 41807040000000000000000);
        _mint(0xacd745EB1F708C323C2167966fcA4503430705E1, 4168034263165550000000000);
        _mint(0xed116130Ec54b9Be4D58ac17A3849e3DF497125a, 244745380000000000000000);
        _mint(0x2Ea252Ba869eEd2a248240A00207583f934404AD, 132772191200000000000000);
        _mint(0xE7fD8119ff58Dc422Da6c6ECfD0f8A16b4610062, 218107327680000000000000);
        _mint(0x8818518F5250ed3Dc7BCF4E539f6B35b54E29b29, 264325010400000000000000);
        _mint(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 339737629167200000000000);
        _mint(0xa23344184E2c6E1aa744E9B7Cd4b513CEa5aFB3c, 257810080000000000000000);
        _mint(0x08fc58b846e69b332D6De7FaCBA6062648490E8D, 159141110700000000000000);
        _mint(0x7E0d4C8Aa8bA9e422cD4414C5e0a9e720d4D2d46, 232551660000000000000000);
        _mint(0x330Da067eA9b7B4dD5f640CF3812Fe3F1212c2C4, 67620441488160000000000);
        _mint(0x1c2Cc5C54F3362Ff2bFDc03c0B1f9664b2073563, 227904110720000000000000);
        _mint(0xb2E9113d7Ac34f7D39662b0e8Ddc769BDec9cbF7, 41626747140000000000000);
        _mint(0x70d976436A90b7Fa90B0E086fec38a446420195D, 35066781848120000000000);
        _mint(0x6390B88a6369D08E28eCE4d741131D6FFbAc224c, 4894907600000000000000);
        _mint(0xeb87C91742dA3AdB33C8f0faF0c0111f1Bdb6B1a, 264325010400000000000000);
        _mint(0x35867F6474a4781eCb49D383aCDf6b929aF143DD, 216059096272800000000000);
        _mint(0x9BAADCCBB7E843d3e4272cd74EE399c0c00f9954, 257810080000000000000000);
        _mint(0x61229A2Ac51B2430d228F58A2658E1770346F0f6, 251341834128000000000000);
        _mint(0xfE4AE074B84e9B13124da976BE15D4F0b38685aF, 244745380000000000000000);
        _mint(0x8cB5d5bf581Af4F3924adbf69a08dB762B946CE2, 232551660000000000000000);
        _mint(0xBE5be2be175E50D04F55BAF299E5f5B2062Ec934, 105388580000000000000000);
        _mint(0xF47AC69c3F6b7A2950523E641F09C80A0559D8e7, 244745380000000000000000);
        _mint(0xADC0B7a58ba5FBD9E8a6980350B39c52704a2f6A, 111114402520000000000000);
        _mint(0x014B5Bb2F3800637e0E7DE077A9af4803AB81E9C, 244745380000000000000000);
        _mint(0x337cf9b5bb45285Eec16661d120c8ab51134C9aA, 239867327604960000000000);
        _mint(0x46b19C2e75e5D19772EFC108d9D5F353047b2148, 265364542449600000000000);
        _mint(0x982C8f4e601a63346b7BD0BEDE7C04e139e4f7BD, 244745380000000000000000);
        _mint(0x9b7f13b9B6d2b0D1623Fd1E1AeF67ECfFeb363e9, 24474538000000000000000);
        _mint(0x8D4b4aAF1F581c5528d006DC3458e76cF2c4555f, 276042408857600000000000);
        _mint(0xBb47df9c00cFc201e709764f31306d02220aA1b4, 4894907600000000000000);
        _mint(0x03fD9C6a9fD55EeA203D2f1e5e6E33ECC42298a6, 70463152980000000000000);
        _mint(0x111484d3345848F43c226995174cda275E9D1D5c, 193889206192000000000000);
        _mint(0x8aD7520f95f76aF7328F8a45baA5D26aC1c79098, 246417661600000000000000);
        _mint(0x47a1147115756883038d000e526A4186902119e0, 126270848088000000000000);
        _mint(0x3023138Cb3AEeAe67c4033015a39b56aF582E3Fc, 257000416992000000000000);
        _mint(0x79d4D61060C4071Cc8530b47EF7b93209a6D0c33, 216273043800000000000000);
        _mint(0xD4a3c4D6Cd564fdcAE0082f3A4419Bb7a4BfaE10, 210777160000000000000000);
        _mint(0x30C45D0F4fBa266731C0BaA7b644D7854C10eeAC, 244745380000000000000000);
        _mint(0x8A85c533693a87837380d9225d226e334663d104, 3445006413780610000000000);
        _mint(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 357063128488000000000000);
        _mint(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 152465850301600000000000);
        _mint(0xc2DC0add26ee49fAbf8E2908B9D5e0991317f922, 23255166000000000000000);
        _mint(0x58eD012303334209F945219fc00F707c0E2C5d80, 28195364560000000000000);
        _mint(0x4775d0038F6D481543A1170Bd4Cfb4f5aEAba23B, 209035200000000000000000);
        _mint(0xFCBdb50E1D99310380BfaB314A66a0f4e2b23875, 13529872998400000000000);
        _mint(0x07BC70d8B22c9431eD35b9007c7646c77053ca75, 20903520000000000000000);
        _mint(0x16CE7d09D38B8E5Dca13980cf9d4BCE2D2244c77, 77343024000000000000000);
        _mint(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 372712897128000000000000);
        _mint(0x559bc75eC6e6AB2079421BbD0ebecAd729a60FB2, 201928003200000000000000);
        _mint(0xdAaB7eB7171aAcD568127E246dE64e28b4C6296E, 258930822224800000000000);
        _mint(0x093ff2FB6B3C815FF955248519ec7B7AF42E665E, 2839046408000000000000);
        _mint(0xA547FDD9210faC0786D05af03Fb289D1947531D4, 257810080000000000000000);
        _mint(0x59b2bbE84dD4566D93e1D344c06D5f17CBfdb073, 257810080000000000000000);
        _mint(0x30A23cFa9767F01dD562f8bCc46ABFb3e45196a9, 146847228000000000000000);
        _mint(0xA6E26DbEf099a1A4c99dD4c90159776C1dbF490B, 276414212800000000000000);
        _mint(0x8C4E1d2CeDaA4C017269592FC70AAF20a9b48aDa, 166287501600000000000000);
        _mint(0x058F3f556cE5E6364dee07b85087de0896251544, 209035200000000000000000);
        _mint(0x27370b2f0D172dA1d506Fa42EFB4a71fC03F99Af, 65803026748800000000000);
        _mint(0x69E1181e26fAB42ab0F73797aA8E8B8dC77628Cf, 209035200000000000000000);
        _mint(0xEa24C5B3B0F9c0B5bb93d6A72747c385a87aCa7B, 68835291360000000000000);
        _mint(0xe53B3CB82815B613062DC657A9FCd6cb77eC595A, 232551660000000000000000);
        _mint(0xEF626c6425A2b077c23c2d747FCfE65777F66B10, 1608579359487280000000000);
        _mint(0x6DB0ba283092dbb17e30639193dbf67091d16ad0, 12237269000000000000000);
        _mint(0x767868f8Bf31973CA8f7559E5EA2cb17537003C5, 232551660000000000000000);
        _mint(0x6eEB9dffb820d13fc7ad5Df4A0b97D4CebFA2A59, 257810080000000000000000);
        _mint(0x4DC9930821b5D073407a36CA435a7965e3c08f3F, 232551660000000000000000);
        _mint(0x2E0F459670Aa7119eD44dA8B8358eb81B372BA3c, 24178396090200000000000);
        _mint(0x21462509020a90abc8864c02dcb43348bcCE63Ec, 2578100800000000000000);
        _mint(0xc3646C9f183A7Ff16aDdB0B778221519a1FAEaC4, 117373264800000000000000);
        _mint(0xc64c8E600a35D3786Cf0B13a46744E010617B080, 2368786886400000000000);
        _mint(0xDC9d5636B830ce0b078Dc2d546b9e1050ab60Bc0, 24474538000000000000000);
        _mint(0xc979748097d71Aa9cF71ad229608C5De0A0965A4, 57683450700700000000000);
        _mint(0x423bdfeB5D25b0C8d5c6Ff598e99EB883A340381, 45569673600000000000000);
        _mint(0x7863B0ABf3926301b380C01Bf7E0ff08133Be6CC, 257810080000000000000);
        _mint(0x22719197Dd5b49C4bCe447230dC70F77E74020Bc, 232551660000000000000000);
        _mint(0x5176fE6b79a153beba945f1BA0fb2FDF4F6a8dEe, 48949076000000000000000);
        _mint(0xb4A7f8acb4537A2A263f829B77fA58d1CD85B706, 253010394030460000000000);
        _mint(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 81430926822960000000000);
        _mint(0x290dbb38d36E12dFfa7EA95d1dD983CAF842db61, 7992112480000000000000);
        _mint(0xD9870A9677778Db6Da1da141D9FaF3CC8C1DBe15, 154529881286000000000000);
        _mint(0xF6CEDBD5DCc702fa7E2afa4f2eBBfa436F28812E, 131483140800000000000000);
        _mint(0xc97C55442099a325ED7b399925846b51d60eaD3B, 53746433840000000000000);
        _mint(0x32F0281E2ab2c728ac592c5006B5cDF35A80B0E3, 213738492000000000000000);
        _mint(0xeE5caE74e334C2F1af65d19052b202c2F6bD4aB4, 257810080000000000000000);
        _mint(0x23c8dC48eb57f7748D2Ed89886581FF95978efd6, 20903520000000000000000);
        _mint(0x899530F3464A37920674B536384c299C6a09EeeE, 40929092160000000000000);
        _mint(0x68c950840858347b7F744f7C5926657e37Fb4392, 232551660000000000000000);
        _mint(0x5B5d95d32f55f08480704077888D713D50c8F18F, 46510332000000000000000);
        _mint(0xE75727bd26e24347D01c33B134d77D0D9bcC6B87, 167204643540000000000000);
        _mint(0x26BC99a54c290a7865DCbF0B1ed8A4f013Ea964f, 244745380000000000000000);
        _mint(0x6789297F7623d5cd5A274df4E82DC0ddc0b96948, 69928284162000000000000);
        _mint(0xd281BE420F04e2fA9F95172c94a8276C32F995fc, 238132899840000000000000);
        _mint(0x41224E44922d2d98aa6360c705772c59AAceC96B, 44315462400000000000000);
        _mint(0xeC14389807f0B6499a032DB73FD8a94c1204a216, 209035200000000000000000);
        _mint(0x03A37D056e747230625839B8dbA6174e077D24b1, 232551660000000000000000);
        _mint(0xF81526aC03a5F38fF58Eb9Cd4b5caAA3d8eE6771, 220299584340000000000000);
        _mint(0x5CBBd3C50DC65FfE4eEABaE2b93eAb52619306c7, 287699291624800000000000);
        _mint(0x1E8c82755F62081Cc7c760730677C5776Da27C32, 244745380000000000000000);
        _mint(0xEd6f4Cdc27EaC292A2560b3EebF592598AD5ee67, 204875399520000000000000);
        _mint(0x25B78d4f814f12C6B2e1D87b28A56143e5322bE4, 264325010400000000000000);
        _mint(0x17809259208A66d81E94B45c7014f791AAcBbB0d, 235334179806000000000000);
        _mint(0xcb5D8b1c5f2564d541d0635576976C83842De95E, 122372690000000000000000);
        _mint(0xfAd9Ca41589B3657d56e1a6b38601dCbc5dAb508, 77085213920000000000000);
        _mint(0x475131c7992A6666969b344Ad8cB8b9f8E98e606, 125107567200000000000000);
        _mint(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 341885190617520000000000);
        _mint(0xa58F504430a6a2d969b959A73D590C54da79F800, 48949076000000000000000);
        _mint(0x40f341145B52905D0af17D3344fBe5ab8f47D679, 257022034715600000000000);
        _mint(0xB07a67678baB935C2cE60edC41463aA5785E9Dd4, 37935533900000000000000);
        _mint(0x80847544A13209B76A70de0022Be3dcaa193F88c, 244745380000000000000000);
        _mint(0x48e36BdBBc54219136FDd20685ccC73166Fe8324, 20678493607200000000000);
        _mint(0x43234e1a1c49023725Af693B6bC5a76C11C46765, 23255166000000000000000);
        _mint(0x0759D0642ceC4265b350c253889D1bF97539E10f, 257810080000000000000000);
        _mint(0x2387DBc688E1F53b3D01a23A4d7ec4577C7F393B, 140926305960000000000000);
        _mint(0x3f947d3fD2eF078f77CF01f781A7392979dFf02e, 177318027810000000000000);
        _mint(0x93a67E0B06f9DC0fdab8a041C34B74Fb29C018f8, 51396529800000000000000);
        _mint(0xe0951E8a48456dE9D31dAE4B22c2e34AF80D6800, 232551660000000000000000);
        _mint(0xE60110EdCDF0Db502b664F6F894f35B8C12414A9, 105388580000000000000000);
        _mint(0xe8a1A820cdc94ca5E2726612A8DC0e7B0E33aDAa, 257810080000000000000000);
        _mint(0x1689aB3994e413046f3d8e153768c7757a015420, 48949076000000000000000);
        _mint(0x49Ec0ed807417b69E2950fA809A60E1994D2dc6B, 39089582400000000000000);
        _mint(0x5DcE7412dAC1860B1c9EaCEaE3a09eD2F4eC7600, 97898152000000000000000);
        _mint(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 491615839714560000000000);
        _mint(0xA576639A4884fb97648111D0CAfe9Bc89ff5436A, 109198037484800000000000);
        _mint(0x4D95Ef6E08fb61207eF4d45B79d8b150D9382c7e, 53486881800000000000000);
        _mint(0x3603b37948C74B6E15C7988aAe9624741E7b2398, 209296494000000000000000);
        _mint(0xEBaCBa195aCcc94E6AC9B34207F3916C41119329, 255790343574480000000000);
        _mint(0x8E367218246f9DF464dD925169c470d8f0622222, 138368237700000000000000);
        _mint(0x4Dcd8D7219240f6e06d3edfE90a2DaCBcefA5a51, 102322730400000000000000);
        _mint(0x4Ac0574BC2249B09808aa8F0dD4130b053889601, 2447453800000000000000);
        _mint(0x53dacCeC0FDa34C30F89cd64ad29A9BBe84d275E, 83213429200000000000000);
        _mint(0x25E7d4c6529DC774Ae1A44E686084273DAB679FB, 292262321005600000000000);
        _mint(0x7c4E6B55f58D5396b82d9128a705f14a36f4EB76, 211404265600000000000000);
        _mint(0xb863769e618825A4650BFb5ae8bF022bB92AD7E6, 76157271828000000000000);
        _mint(0x8b832f9201651e5F193f004997cCb507a19E2700, 293079578959200000000000);
        _mint(0x93967805fAa6eabe9de62D578B1f076863908133, 273405499488000000000000);
        _mint(0x12ee88A73aB1d6609863f6C863Fc26b017627542, 22516574960000000000000);
        _mint(0x1349DCDd92BA65Cf2234eD8c61C72DdF1f95400E, 1608579359487280000000000);
        _mint(0xc6A3EE287edFce5bdeF89121359fA63b50CB9cAB, 218392138140000000000000);
        _mint(0xfA01965486e0B6Bfe4F314b3C1D7914ABc0D2F80, 124264458560000000000000);
        _mint(0x44EE1512f5d7455523CdA8338b04aE6A60a99dE4, 50586518400000000000000);
        _mint(0xdC89fc2f0d8B73D769C909eB04dE30E235e7AD53, 2871008761060000000000);
        _mint(0xe674661FDb5bcA205752EA96F7D7Dca631a006C0, 24450063462000000000000);
        _mint(0xAaF4394aFBe1B7c6c8379DA08a999dA788a9728C, 23683061054400000000000);
        _mint(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 315892043244800000000000);
        _mint(0x5aDEd2a2748e0dda11D5Abbb0d423a94B828a5f0, 24474538000000000000000);
        _mint(0x503C2c166b9A2785Fa944d6D46b0247b1d1A5e8d, 277389710400000000000000);
        _mint(0xDeda2F75187f96965eB24FD53123F42A5ef342a8, 77343024000000000000000);
        _mint(0x24F4524Ea5CEB315f27543E709CF881F370Bf086, 22993872000000000000000);
        _mint(0x0e6ce52C1D0257808be60C3f799172Bd1Ad30028, 232551660000000000000000);
        _mint(0x704b0E7EcFf4b953063b7B38f8F4c6A17021A72A, 257810080000000000000000);
        _mint(0x6EEC71FC6195B0F835F19cAA27b29461751128ce, 24474538000000000000000);
        _mint(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 1822649362257240000000000);
        _mint(0xa111006cCb092AA6A4044bc322135d8B0842A9f2, 25820637590000000000000);
        _mint(0x612772eC0968C7bf79856ca3288ef383Ec90Da9d, 208831390680000000000000);
        _mint(0x7412C8B906815C25C9031b8B3B9F4805015aC7f2, 26920033836960000000000);
        _mint(0xEC931D7beF828D5bEADac291490A71faE80a401b, 48704330620000000000000);
        _mint(0x19347a84d4550E29623ccA6e641cCb6e65Fb9BBA, 316420762944000000000000);
        _mint(0x2AA4782C4CD8F26116B753016d3D789C45c077dc, 244745380000000000000000);
        _mint(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 497634281030260000000000);
        _mint(0x546B76e990AD05F904C7E1eF648CaB8234C7311C, 41807040000000000000000);
        _mint(0xb7d0fA0669730E46F9faE6D3a89BC26832B55DfE, 77552059200000000000000);
        _mint(0x844950422e1f7306e536fA68A6Eff106151cFf24, 4651033200000000000000);
        _mint(0x65EBd58D35231c99c401da6B49DeeB5e9Be93748, 2578100800000000000000);
        _mint(0xCec4df3865be446e9e8D2fd9cB9e182F698C6E1b, 232551660000000000000000);
        _mint(0x91e0c71217225a4870a6eF35a7cA0B674941A746, 88369630800000000000000);
        _mint(0xd0A26322aBFaA561DA11713e76AF4e5611B9A4fd, 27441095880000000000000);
        _mint(0x78a607231617D6E0e3719ed3e127e5084f6CB1b6, 40552828800000000000000);
        _mint(0x850ec325A5cEa0ab75aCD402C9AE4DBF04B5Ed9D, 128905040000000000000000);
        _mint(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 364523803811200000000000);
        _mint(0x8D24E10d251A575cEbe15A18c8f2E9e956F57b60, 51304205920000000000000);
        _mint(0x6E498f21f09919914F5cC486f7BE690E2beBd9E7, 244745380000000000000000);
        _mint(0x36917bc886E619521D76F8994DB962Fc1E748E99, 257810080000000000000000);
        _mint(0xED699e481ADb3111F23742F0646A5c7695EebD10, 232551660000000000000000);
        _mint(0x70d79418A686eE65a449C2d06220E643155f0f14, 257810080000000000000000);
        _mint(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 357387411761600000000000);
        _mint(0xdc9E7a6A086DbB784C7BD7d84B4884B0EA1F168A, 12628861608000000000000);
        _mint(0x08Eb3f0457BF0De318F46B886Df6805fC788C1d2, 46277780340000000000000);
        _mint(0x9650a79FC1BCCBd27DfC0dfB76769d15C54472b9, 177204364920000000000000);
        _mint(0x67Ae0ec54D93EDEC844C007bCaE312102ee5F3f8, 217076087360000000000000);
        _mint(0x61b0660f216ff73f069F4F68Ec5e8AB8795DFe7E, 12890504000000000000000);
        _mint(0xcf1D71B02Aa523F72Aca3f312505f01058772D45, 244745380000000000000000);
        _mint(0x7245AA3377401C1a0482219053edC8545D65920f, 128905040000000000000000);
        _mint(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 284749382527500000000000);
        _mint(0x024e0b8E22743d89E0465D30C337F951918705fa, 274672252800000000000000);
        _mint(0x8702ffdd9E3495A0BF81EB315f966284d41FB594, 109029624792000000000000);
        _mint(0xaBaECA5Fd546cCfCAEbB6Fa1B69A6c6bDC9B44eC, 33950100132080000000000);
        _mint(0x128C688929B28fFD468705220EcDd71A74E81B89, 24474538000000000000000);
        _mint(0x234cc5b3C115E25Efc9E3b9C5bC8Bfc6B69cB5E6, 262172560138940000000000);
        _mint(0x0495e62e568d477c10De7116c8938350e2da690E, 48949076000000000000000);
        _mint(0xc8219b660827326B3f55eA7776b6578A0A20D2cF, 89341644480000000000000);
        _mint(0xAbE2D1bBc5833Da77AF5e79Ee08DBa4b9Acd2114, 51562016000000000000000);
        _mint(0xEA9d1d1fA0B7BED82f0d2723883f0543a8A18E9a, 50272965600000000000000);
        _mint(0x094fb07EFf26405c672a208aA607f34E0B5D44F8, 51641275180000000000000);
        _mint(0x22F12615B4045a222393455B5aA9c1934071eD52, 217900905420000000000000);
        _mint(0x178132F6c553ce96D4B47Ec224a5C37E76BE39dd, 209035200000000000000000);
        _mint(0x7be8c96A98CB2FE2Fd6C59edd2a83CeBb3233bA2, 208133735700000000000000);
        _mint(0xC1Ed11d231e512982CD87F8b5861A0fEd7a19153, 272550545520000000000000);
        _mint(0xDcF8023f18409005207026DE7F0D1e780A94F742, 276083937184000000000000);
        _mint(0xc9e24327B2bd18Dd62D870A993A273c16C895cf6, 103124032000000000000000);
        _mint(0xf4fd96326fcF4E8b90C44fda94622F9c05F17DA9, 42155432000000000000000);
        _mint(0xceaE30276B9fD5FA44366167e64728180eb3962c, 2108579359487280000000000);
        _mint(0xC671e68226AE0AA544B6Df8F2f16Cf6232e187eA, 122089621500000000000000);
        _mint(0xFc6D028371e3eCED057f7B8A8A57f7C68ad306D4, 97671697200000000000000);
        _mint(0x503bb794fe7A57A15FB7E7967Af22BF341682C5B, 232086556680000000000000);
        _mint(0xe7e25b26d7d16689a4Ba3f5410B85e30bd297D39, 53135005009020000000000);
        _mint(0xbCE7B4a46f77DE88d32cA0F22BA1F94F7C30db74, 260697552896000000000000);
        _mint(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 190862133492580000000000);
        _mint(0x53cb6a0B87F0c438d033C59Ad757f6536564db28, 210777160000000000000000);
        _mint(0x5db0CE4BE877074f838Ec85eb196784ee529dF15, 223697277320000000000000);
        _mint(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 260792315520000000000000);
        _mint(0xf1a51ea68ACEfC4395B5bC12a8c5d94F4d1a2470, 232551660000000000000000);
        _mint(0x68638d183B99095740BdE4Eb21f6742DDbd585b4, 44543659160000000000000);
        _mint(0x994b046DeB3d24B5B242D4ee07D00e1Fed3f3261, 305522364400000000000000);
        _mint(0x5159F99d35Cb74796dE5664Da456b79a21ac5449, 232551660000000000000000);
        _mint(0xb4536dC4950b53e3c16Fb85c5a56F9Be239A7b6f, 25781008000000000000000);
        _mint(0x871D583DEB3083993b28487bEb934EEf155E0118, 83951149260000000000000);
        _mint(0xe2D0baFac71db8c6e4884C4Dd010264fFA49C44b, 199296772620000000000000);
        _mint(0x89728067216ca54361060316d766bf681853E7Fa, 244745380000000000000000);
        _mint(0x5f25a86383888F74B944576c92d4ec75b35eA66d, 14529827716800000000000);
        _mint(0x880A9d891b285650dEfE2969ED22608D26dDFFF3, 34882749000000000000000);
        _mint(0xd34a20E69403aa10913dd91455aEe574f7611527, 95868768600000000000000);
        _mint(0x8DD3382eB29C4ecCf48482d7d7ED93301638b702, 7992112480000000000000);
        _mint(0x3e091d480d0e3429fAB8E072075b7502f218Ebb8, 226970420160000000000000);
        _mint(0x8eeCF761a6AC8076F2A1C23C4f87345B24E3f477, 26187755660000000000000);
        _mint(0xC531E47F882A34543Cc77E92FFbba93D3Ea11117, 173227731534000000000000);
        _mint(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 207824572639200000000000);
        _mint(0x9944aC84145836C679acA9968992E12A9330Ed2c, 8566088300000000000000);
        _mint(0x1Eee9A2dB92C46EAfF06B3C31E34db7BD1ECDdaF, 77447541600000000000000);
        _mint(0xf6e03430B73670dc1BDdC2520Bebf08b3a79fe47, 20903520000000000000000);
        _mint(0x5C386aD5f389242C066f19Bc3b423A6097e9efb7, 122372690000000000000000);
        _mint(0xbD793d8E9A131b9d31D8b3695676C0a408c0FDC4, 116275830000000000000000);
        _mint(0x7C19a5AC994Cf5bF2c1AED71D4deF63D96ad88b8, 24474538000000000000000);
    }
}