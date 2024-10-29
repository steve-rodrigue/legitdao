// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Affiliates is ERC721, Ownable {

    // using Math for uint256 type
    using Math for uint256;

    struct Tree {
        address addr;
        Tree[] list;
    }

    uint256 private constant DESCALE = 10000;
    uint256[7] public levelRatios = [
        5333,
        2666,
        999,
        334,
        334,
        167,
        167
    ];

    mapping(address => uint256) public paymentBook;

    // referral trees:
    mapping(address => address[]) public parentChildren;
    mapping(address => address) public childParent;

    // offering system:
    mapping(address => mapping(uint256 => uint256)) public offersByAddressTokenIdPrice;
    mapping(uint256 => address) public tokenIdOfferer;
    mapping(address => uint256[]) public offerererTokenIds;

    // next token id:
    uint32 public nextTokenId = 0;

    // erc-20 currency address:
    address public currencyAddress = address(0);

    // erc-20 founder address:
    address public founderAddress = address(0);


    // events:
    event CurrencyAddressSet(address indexed currencyAddress);
    event FounderAddressSet(address indexed currencyAddress);
    event PaymentReceived(address indexed user, uint256 shareAmount, uint256 totalAmount);
    event PaymentClaimed(address indexed user, uint256 amount);
    event RegisterReferral(address indexed owner, address indexed referral);
    event RegisterOffer(address indexed user, uint256 tokenId, uint256 amount);
    event WithdrawOffer(address indexed user, uint256 tokenId);
    event AcceptOffer(address indexed user, uint256 tokenId, uint256 price);

    constructor()
        ERC721("LegitDAO Affiliates", "LEGIT-AFF")
        Ownable(msg.sender)
    {
        // initial referral tree:
        initialTreeRegister();
    }

    function setCurrencyAddress(address currAddr) public onlyOwner {
        require(currencyAddress == address(0), "Currency Address already set");
        require(currAddr != address(0), "Invalid address");
        require(IERC20(currAddr).totalSupply() != 0, "Provided contract is not a valid erc20");
        currencyAddress = currAddr;

        // emit:
        emit CurrencyAddressSet(currencyAddress);
    }

    function setFounderAddress(address fdrAddress) public onlyOwner {
        require(founderAddress == address(0), "Founder Address already set");
        require(fdrAddress != address(0), "Invalid address");
        require(IERC20(fdrAddress).totalSupply() != 0, "Provided contract is not a valid erc20");
        founderAddress = fdrAddress;

        // emit:
        emit FounderAddressSet(currencyAddress);
    }

    function receivePayment(address child, uint256 amount) public {
        return _receivePayment(child, amount, 0, 0);
    }

    function claimPayment(address sendTo, uint256 amount) public {
        require(amount > 0, "amount must be greater than zero");
        require(paymentBook[msg.sender] > 0, "sender has 0 balance");

        uint256 transferAmount = amount;
        if (transferAmount > paymentBook[msg.sender]) {
            transferAmount = paymentBook[msg.sender];
        }

        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom(address(this), sendTo, transferAmount);
        require(success, "Token transfer failed");

        // adjust the book:
        paymentBook[msg.sender] -= transferAmount;

        // emit:
        emit PaymentClaimed(msg.sender, transferAmount);
    }

    function register(address child) public {
        return _register(msg.sender, child);
    }

    function getParent(address child) public view returns(address) {
        return childParent[child];
    }

    function getChildren() public view returns(address[] memory) {
        return parentChildren[msg.sender];
    }

    function registerOffer(uint256 tokenId, uint256 price) public {
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(price > 0, "price must be greater than zero");

        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom(msg.sender, address(this), price);
        require(success, "Token transfer failed");

        uint256 offerPrice = offersByAddressTokenIdPrice[msg.sender][tokenId];
        if (offerPrice > 0) {
            require(offerPrice > price, "current offer registered higher than your price");

            // withdraw the current offer:
            _withdrawOffer(msg.sender, tokenId);
        }

        // register the new offer:
        offersByAddressTokenIdPrice[msg.sender][tokenId] = price;
        tokenIdOfferer[tokenId] = msg.sender;
        offerererTokenIds[msg.sender].push(tokenId);

        // emit:
        emit RegisterOffer(msg.sender, tokenId, price);
    }

    function withdrawOffer(uint256 tokenId) public {
        _withdrawOffer(msg.sender, tokenId);
    }

    function getOfferForToken(uint256 tokenId) public view returns(uint256) {
        address offerer = tokenIdOfferer[tokenId];
        return offersByAddressTokenIdPrice[offerer][tokenId];
    }

    // accept a registered offer:
    function acceptOffer(address sendTo, uint256 tokenId) public {
        require(currencyAddress != address(0), "currency contract address has not been set");
        address owner = _ownerOf(tokenId);
        require(owner == msg.sender, "current address is not the owner of that tokenId");

        uint256 offerPrice = getOfferForToken(tokenId);
        
        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom(address(this), sendTo, offerPrice);
        require(success, "Token transfer failed");

        _deleteOffer(owner, tokenId);

        // emit:
        emit AcceptOffer(owner, tokenId, offerPrice);
    }

    // returns the token ids the sender made an offer on
    function getMyTokenOffers() public view returns(uint256[] memory) {
        return offerererTokenIds[msg.sender];
    }

    // receive a payment to the affiliate it and split it among its parent.
    // if there is no 7 levels, send the remaining to the founders contract:
    function _receivePayment(address child, uint256 amount, uint256 level, uint256 totalPaid) private {
        require(amount > 0, "amount must be greater than zero");
        require(currencyAddress != address(0), "currency contract address has not been set");
        require(levelRatios[level] > 0, "the level must be greater tahn zero");
        require(amount <= totalPaid, "the amount cannot exceed the total paid");

        if (level >= levelRatios.length) {
            return;
        }

        // find the parent:
        address parent = childParent[child];

        // if there is no parent address:
        if (parent == address(0)) {
            // calculate the remaining:
            uint256 remaining = amount - totalPaid;
            
            //change the payment in the book:
            paymentBook[founderAddress] = remaining;

            // return
            return;
        }

        // find the scaled amount:
        (bool scaledSuccess,  uint256 scaled) = levelRatios[level].tryMul(amount);
        require(scaledSuccess, "levelRatios[level] * amount overflows");

        // descale the amount:
        (bool descaledSuccess,  uint256 descaled) = scaled.tryDiv(DESCALE);
        require(descaledSuccess, "scaled / DESCALE overflows");

        // find the payment total:
        (bool paymentSuccess,  uint256 payment) = paymentBook[parent].tryAdd(descaled);
        require(paymentSuccess, "paymentBook[parent] + descaled overflows");

        //change the payment in the book:
        paymentBook[parent] = payment;

        // emit:
        emit PaymentReceived(parent, payment, amount);

        // continue next level:
        _receivePayment(parent, amount, level++, totalPaid + payment);
    }

    function _register(address parent, address child) private {
        childParent[child] = parent;
        parentChildren[parent].push(child);
        _mint(parent, nextTokenId++);

        // emit:
        emit RegisterReferral(parent, child);
    }

    function _withdrawOffer(address from, uint256 tokenId) private {
        require(currencyAddress != address(0), "currency contract address has not been set");
        
        uint256 offerPrice = offersByAddressTokenIdPrice[from][tokenId];
        require(offerPrice > 0, "no offer registered from the provided address");

        IERC20 token = IERC20(currencyAddress);
        bool success = token.transferFrom(address(this), msg.sender, offerPrice);
        require(success, "Token transfer failed");
        
        _deleteOffer(from, tokenId);

        // emit:
        emit WithdrawOffer(from, tokenId);
    }

    function _deleteOffer(address from, uint256 tokenId) private {
        delete tokenIdOfferer[tokenId];
        delete offersByAddressTokenIdPrice[from][tokenId];

        // delete and re-order:
        for (uint256 i = tokenId; i < offerererTokenIds[from].length - 1; i++) {
            offerererTokenIds[from][i] = offerererTokenIds[from][i + 1];
        }

        offerererTokenIds[from].pop();
    }

    // method overloads:
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        address[] memory childList = parentChildren[from];
        for (uint256 i = 0; i < childList.length; i++) {
            address child = childList[i];
            parentChildren[to].push(child);
            childParent[child] = to;
        }

        delete parentChildren[from];
        return super.safeTransferFrom(from, to, tokenId, data);
    }

    function initialTreeRegister() private {
        _register(0x46b19C2e75e5D19772EFC108d9D5F353047b2148, 0xEC931D7beF828D5bEADac291490A71faE80a401b);
        _register(0x46b19C2e75e5D19772EFC108d9D5F353047b2148, 0x058F3f556cE5E6364dee07b85087de0896251544);

        _register(0x35867F6474a4781eCb49D383aCDf6b929aF143DD, 0x3e091d480d0e3429fAB8E072075b7502f218Ebb8);

        _register(0xd281BE420F04e2fA9F95172c94a8276C32F995fc, 0xA28E98B686096AC65474a27e9b3A80e4072E613f);

        _register(0xc979748097d71Aa9cF71ad229608C5De0A0965A4, 0xe7e25b26d7d16689a4Ba3f5410B85e30bd297D39);
        _register(0xc979748097d71Aa9cF71ad229608C5De0A0965A4, 0x1689aB3994e413046f3d8e153768c7757a015420);

        _register(0x61229A2Ac51B2430d228F58A2658E1770346F0f6, 0x22F12615B4045a222393455B5aA9c1934071eD52);
        _register(0x61229A2Ac51B2430d228F58A2658E1770346F0f6, 0x503bb794fe7A57A15FB7E7967Af22BF341682C5B);

        _register(0xc64c8E600a35D3786Cf0B13a46744E010617B080, 0x7863B0ABf3926301b380C01Bf7E0ff08133Be6CC);

        _register(0x25E7d4c6529DC774Ae1A44E686084273DAB679FB, 0x5db0CE4BE877074f838Ec85eb196784ee529dF15);
        _register(0x25E7d4c6529DC774Ae1A44E686084273DAB679FB, 0xCec4df3865be446e9e8D2fd9cB9e182F698C6E1b);
        _register(0x25E7d4c6529DC774Ae1A44E686084273DAB679FB, 0x4DC9930821b5D073407a36CA435a7965e3c08f3F);

        _register(0x8aD7520f95f76aF7328F8a45baA5D26aC1c79098, 0x07BC70d8B22c9431eD35b9007c7646c77053ca75);

        _register(0x2f5B28Dd625Ca194894165EDAA4704eE75d4E4AB, 0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a);
        _register(0x2f5B28Dd625Ca194894165EDAA4704eE75d4E4AB, 0x3603b37948C74B6E15C7988aAe9624741E7b2398);
        _register(0x2f5B28Dd625Ca194894165EDAA4704eE75d4E4AB, 0xC671e68226AE0AA544B6Df8F2f16Cf6232e187eA);

        _register(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 0xEe48960e29c896a4726A17Ec65A9dD39555476B0);
        _register(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 0xAbE2D1bBc5833Da77AF5e79Ee08DBa4b9Acd2114);
        _register(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 0x40f341145B52905D0af17D3344fBe5ab8f47D679);
        _register(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 0x178132F6c553ce96D4B47Ec224a5C37E76BE39dd);
        _register(0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F, 0xc8219b660827326B3f55eA7776b6578A0A20D2cF);

        _register(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 0x0759D0642ceC4265b350c253889D1bF97539E10f);
        _register(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 0xe8a1A820cdc94ca5E2726612A8DC0e7B0E33aDAa);
        _register(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 0x80847544A13209B76A70de0022Be3dcaa193F88c);
        _register(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 0x81b01fD31017db4A6D85C098C26902Ba15E29625);
        _register(0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC, 0xe6EfE00342D70cB85BE60AB796Ab98cC2a71f23B);

        _register(0xEBaCBa195aCcc94E6AC9B34207F3916C41119329, 0x337cf9b5bb45285Eec16661d120c8ab51134C9aA);

        _register(0x25B78d4f814f12C6B2e1D87b28A56143e5322bE4, 0xfE4AE074B84e9B13124da976BE15D4F0b38685aF);

        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x32F0281E2ab2c728ac592c5006B5cDF35A80B0E3);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x43ddC99e9BaF04b12979b1ecc9272A0585b27c90);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0xF81526aC03a5F38fF58Eb9Cd4b5caAA3d8eE6771);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x880A9d891b285650dEfE2969ED22608D26dDFFF3);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x8E367218246f9DF464dD925169c470d8f0622222);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x49Ec0ed807417b69E2950fA809A60E1994D2dc6B);
        _register(0xCa9E4ec800b85345b186dCdA5C02671A861dC067, 0x69E1181e26fAB42ab0F73797aA8E8B8dC77628Cf);

        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x9b7f13b9B6d2b0D1623Fd1E1AeF67ECfFeb363e9);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x61178ed786321F6acdF01633E336D94Fc42ec53A);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x5f25a86383888F74B944576c92d4ec75b35eA66d);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0xD2CB8B857b1AAbE1f4d7404eBe260CCa0862370D);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x08Eb3f0457BF0De318F46B886Df6805fC788C1d2);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x621Cb7f95cd54B6884CA331CFb5e610Fa5Cb092d);
        _register(0x072A9B89F4462d3c2F9183e82027b42299B74fD9, 0x3a59Dbb440DcB76b37C67c2891679270C5909E51);

        _register(0xb863769e618825A4650BFb5ae8bF022bB92AD7E6, 0x844950422e1f7306e536fA68A6Eff106151cFf24);

        _register(0xfb50EFfC86D5bAe52DD18578d9A0c26Be5C0E8C2, 0x6E498f21f09919914F5cC486f7BE690E2beBd9E7);

        _register(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 0x8C4E1d2CeDaA4C017269592FC70AAF20a9b48aDa);
        _register(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 0x2Ea252Ba869eEd2a248240A00207583f934404AD);
        _register(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 0x8cB5d5bf581Af4F3924adbf69a08dB762B946CE2);
        _register(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 0x4D95Ef6E08fb61207eF4d45B79d8b150D9382c7e);
        _register(0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9, 0x2387DBc688E1F53b3D01a23A4d7ec4577C7F393B);

        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0x25E7d4c6529DC774Ae1A44E686084273DAB679FB);
        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0x8c9a61A81863744A3C778f497F2853C9eE2C9D50);
        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0x35867F6474a4781eCb49D383aCDf6b929aF143DD);
        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0xCFc8Be6e4Ff4e75ca8C95ed1a7Efc4eA8D894d0f);
        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0x475131c7992A6666969b344Ad8cB8b9f8E98e606);
        _register(0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989, 0xC555Acf73A1164f7F2eEe5E7F59FEE502F17AFec);

        _register(0x337cf9b5bb45285Eec16661d120c8ab51134C9aA, 0x6789297F7623d5cd5A274df4E82DC0ddc0b96948);
        _register(0x337cf9b5bb45285Eec16661d120c8ab51134C9aA, 0x44EE1512f5d7455523CdA8338b04aE6A60a99dE4);

        _register(0xc6A3EE287edFce5bdeF89121359fA63b50CB9cAB, 0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe);

        _register(0xb4A7f8acb4537A2A263f829B77fA58d1CD85B706, 0xc979748097d71Aa9cF71ad229608C5De0A0965A4);

        _register(0xA3ec1aC881f6397d7AC0916c91013A159b2Fa9A7, 0x61b0660f216ff73f069F4F68Ec5e8AB8795DFe7E);

        _register(0x41224E44922d2d98aa6360c705772c59AAceC96B, 0xEEc9AED9D7d5430DbEe4f6425c5974a6Dce5dD78);
        _register(0x41224E44922d2d98aa6360c705772c59AAceC96B, 0xa6E9ce90646c5624C7Cd530422EAA3A6662f1992);

        _register(0x994b046DeB3d24B5B242D4ee07D00e1Fed3f3261, 0xA547FDD9210faC0786D05af03Fb289D1947531D4);
        _register(0x994b046DeB3d24B5B242D4ee07D00e1Fed3f3261, 0xA576639A4884fb97648111D0CAfe9Bc89ff5436A);
        _register(0x994b046DeB3d24B5B242D4ee07D00e1Fed3f3261, 0x9650a79FC1BCCBd27DfC0dfB76769d15C54472b9);

        _register(0x2E797DB6a3c9857dd7E32dB7Abb18D1bc919Fe53, 0xc9e24327B2bd18Dd62D870A993A273c16C895cf6);

        _register(0x093ff2FB6B3C815FF955248519ec7B7AF42E665E, 0xBb47df9c00cFc201e709764f31306d02220aA1b4);

        _register(0x70d976436A90b7Fa90B0E086fec38a446420195D, 0xFCBdb50E1D99310380BfaB314A66a0f4e2b23875);
        _register(0x70d976436A90b7Fa90B0E086fec38a446420195D, 0x89CbF332571F54E2D1CEAdDC2B91b6A96f21df00);

        _register(0x58eD012303334209F945219fc00F707c0E2C5d80, 0x5B5d95d32f55f08480704077888D713D50c8F18F);

        _register(0x5CBBd3C50DC65FfE4eEABaE2b93eAb52619306c7, 0x46b19C2e75e5D19772EFC108d9D5F353047b2148);

        _register(0x283Aaf54D6e4d0FA42b358A098597E4Ba3f346e1, 0xc96eC4dBF43aB7723c1141B327302b0067881f3F);
        _register(0x283Aaf54D6e4d0FA42b358A098597E4Ba3f346e1, 0x4775d0038F6D481543A1170Bd4Cfb4f5aEAba23B);
        _register(0x283Aaf54D6e4d0FA42b358A098597E4Ba3f346e1, 0x24F4524Ea5CEB315f27543E709CF881F370Bf086);

        _register(0xC1Ed11d231e512982CD87F8b5861A0fEd7a19153, 0xd281BE420F04e2fA9F95172c94a8276C32F995fc);
        _register(0xC1Ed11d231e512982CD87F8b5861A0fEd7a19153, 0x365d913C0a29D709FE3e649A1376951661b96FD1);

        _register(0xc691c060ebEeaB5655cC997246A962E7162e1e8e, 0x128C688929B28fFD468705220EcDd71A74E81B89);

        _register(0x21A7619492f3D5aa58345556863026bBa112Db56, 0x03fD9C6a9fD55EeA203D2f1e5e6E33ECC42298a6);

        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x16CE7d09D38B8E5Dca13980cf9d4BCE2D2244c77);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xb4536dC4950b53e3c16Fb85c5a56F9Be239A7b6f);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xDeda2F75187f96965eB24FD53123F42A5ef342a8);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xCee382F4fF237942366a811D9ED596850E46A050);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xb863769e618825A4650BFb5ae8bF022bB92AD7E6);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x7245AA3377401C1a0482219053edC8545D65920f);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x41E0d6fD4F722F39b3168E2CAC4da2E0a2B8fE6B);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xD9870A9677778Db6Da1da141D9FaF3CC8C1DBe15);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x0850A184714490B7EF2204c83e69532080F4845f);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xEA9d1d1fA0B7BED82f0d2723883f0543a8A18E9a);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x8b832f9201651e5F193f004997cCb507a19E2700);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x65EBd58D35231c99c401da6B49DeeB5e9Be93748);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x1D3149339fdc6C70e0Dd5de824d821848FDACD05);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xDC9d5636B830ce0b078Dc2d546b9e1050ab60Bc0);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x8eeCF761a6AC8076F2A1C23C4f87345B24E3f477);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x941bbd3d449Cd092781f6f12819DaBD537c36947);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0x6390B88a6369D08E28eCE4d741131D6FFbAc224c);
        _register(0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE, 0xdC89fc2f0d8B73D769C909eB04dE30E235e7AD53);

        _register(0xA576639A4884fb97648111D0CAfe9Bc89ff5436A, 0xfA01965486e0B6Bfe4F314b3C1D7914ABc0D2F80);

        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0xB900548E21B6cbb11f578FCA70DFB80CFBEb29d5);
        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0xb2f44b1A4f1CA5c7333151D8a730Af6Ac71ECd63);
        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0x546B76e990AD05F904C7E1eF648CaB8234C7311C);
        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0x449B3B54c81883680e09F2197838c4d99E1D02Ad);
        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0xEF98C81BD01bc0287d6ABbA8ad3d9496D93dEd76);
        _register(0x1D3149339fdc6C70e0Dd5de824d821848FDACD05, 0x23c8dC48eb57f7748D2Ed89886581FF95978efd6);

        _register(0x40f341145B52905D0af17D3344fBe5ab8f47D679, 0xEd6f4Cdc27EaC292A2560b3EebF592598AD5ee67);
        _register(0x40f341145B52905D0af17D3344fBe5ab8f47D679, 0x79d4D61060C4071Cc8530b47EF7b93209a6D0c33);

        _register(0xA6E26DbEf099a1A4c99dD4c90159776C1dbF490B, 0xED699e481ADb3111F23742F0646A5c7695EebD10);

        _register(0xFCBdb50E1D99310380BfaB314A66a0f4e2b23875, 0x8DD3382eB29C4ecCf48482d7d7ED93301638b702);

        _register(0x8D4b4aAF1F581c5528d006DC3458e76cF2c4555f, 0x1c2Cc5C54F3362Ff2bFDc03c0B1f9664b2073563);

        _register(0xa4BB241C53eAA799071E6Ad7b716DbA89A441f69, 0x8c5a840B5a9C2D78f665C93C63c3061F187C3346);

        _register(0xacd745EB1F708C323C2167966fcA4503430705E1, 0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a);

        _register(0xD9870A9677778Db6Da1da141D9FaF3CC8C1DBe15, 0xdc9E7a6A086DbB784C7BD7d84B4884B0EA1F168A);

        _register(0xaBaECA5Fd546cCfCAEbB6Fa1B69A6c6bDC9B44eC, 0x7412C8B906815C25C9031b8B3B9F4805015aC7f2);
        _register(0xaBaECA5Fd546cCfCAEbB6Fa1B69A6c6bDC9B44eC, 0x68638d183B99095740BdE4Eb21f6742DDbd585b4);

        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0x8Ae39c6AB7f21e06B21e8D725F87f604be371fF9);
        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0xc97C55442099a325ED7b399925846b51d60eaD3B);
        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0xa58F504430a6a2d969b959A73D590C54da79F800);
        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0x93a67E0B06f9DC0fdab8a041C34B74Fb29C018f8);
        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0xa111006cCb092AA6A4044bc322135d8B0842A9f2);
        _register(0x1c0370b8711059cB73937B407fB18Cf7BDb04f00, 0xE75727bd26e24347D01c33B134d77D0D9bcC6B87);

        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x6eEB9dffb820d13fc7ad5Df4A0b97D4CebFA2A59);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x3e2Ea46bdFE5eC7F1A12B3F24d47439E1b5e9eBf);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x405481f2d0031115a14e3E3af0283cae429D93Fb);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x024e0b8E22743d89E0465D30C337F951918705fa);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xE8c762AE04480c230eE51f7cAaCF3C3C6A98a5aC);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x1c0370b8711059cB73937B407fB18Cf7BDb04f00);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x82094DfCD0e9d8C57C89a4fFD5491F7B16833fcE);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xF6CEDBD5DCc702fa7E2afa4f2eBBfa436F28812E);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x7c4E6B55f58D5396b82d9128a705f14a36f4EB76);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x7946c0c8807b8458f32DCF6aad0ad6807907e6C5);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xA6E26DbEf099a1A4c99dD4c90159776C1dbF490B);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x8D4b4aAF1F581c5528d006DC3458e76cF2c4555f);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xfb50EFfC86D5bAe52DD18578d9A0c26Be5C0E8C2);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xA3ec1aC881f6397d7AC0916c91013A159b2Fa9A7);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xB4748D7f8c30c637bf1C7A801E19Be5cB2dA7A8F);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xE7fD8119ff58Dc422Da6c6ECfD0f8A16b4610062);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x9f3D84a5F8f9beb9ef03257b511EbF02894a5955);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x1D446853cb843c890895cc86b94204C44FDFc2B6);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x67Ae0ec54D93EDEC844C007bCaE312102ee5F3f8);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x850ec325A5cEa0ab75aCD402C9AE4DBF04B5Ed9D);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xb21d65B8Dd5D419592915a1D9BF281b7036e4CA7);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x2f5B28Dd625Ca194894165EDAA4704eE75d4E4AB);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x21FB0f62ADbf72fb7b515552DfC4B243AEF5439c);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x5CBBd3C50DC65FfE4eEABaE2b93eAb52619306c7);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x5F4113BFCD43307d2382D968327231351b58A5E4);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xb4A7f8acb4537A2A263f829B77fA58d1CD85B706);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x312FC133481fDc7d08a1EcdB1EE3f0208cDeBc39);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x7C19a5AC994Cf5bF2c1AED71D4deF63D96ad88b8);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xcb5D8b1c5f2564d541d0635576976C83842De95E);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x30C45D0F4fBa266731C0BaA7b644D7854C10eeAC);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x30A23cFa9767F01dD562f8bCc46ABFb3e45196a9);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x8818518F5250ed3Dc7BCF4E539f6B35b54E29b29);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xaBaECA5Fd546cCfCAEbB6Fa1B69A6c6bDC9B44eC);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xa4BB241C53eAA799071E6Ad7b716DbA89A441f69);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x6EEC71FC6195B0F835F19cAA27b29461751128ce);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xeD45A63726EBdB50573C8dee4e961FdBF20e0e4a);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xed116130Ec54b9Be4D58ac17A3849e3DF497125a);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x13dA579450B27523006531Dfcf8bB63500E4f871);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xcf1D71B02Aa523F72Aca3f312505f01058772D45);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xdAaB7eB7171aAcD568127E246dE64e28b4C6296E);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xe0951E8a48456dE9D31dAE4B22c2e34AF80D6800);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x27370b2f0D172dA1d506Fa42EFB4a71fC03F99Af);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x03A37D056e747230625839B8dbA6174e077D24b1);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x283Aaf54D6e4d0FA42b358A098597E4Ba3f346e1);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xe2D0baFac71db8c6e4884C4Dd010264fFA49C44b);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xC1Ed11d231e512982CD87F8b5861A0fEd7a19153);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x29CBccD01D8d2d3A4f4C437c4Ae5039362DF95e2);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xbD793d8E9A131b9d31D8b3695676C0a408c0FDC4);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x70d976436A90b7Fa90B0E086fec38a446420195D);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xE60110EdCDF0Db502b664F6F894f35B8C12414A9);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xBE5be2be175E50D04F55BAF299E5f5B2062Ec934);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xD4a3c4D6Cd564fdcAE0082f3A4419Bb7a4BfaE10);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xc4cE1C95F0ed3aE7F1428712C1E768CEF2462eC2);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0xf4fd96326fcF4E8b90C44fda94622F9c05F17DA9);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x415625003693F35ab608Bc040600c9A5BAd994B8);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x2E797DB6a3c9857dd7E32dB7Abb18D1bc919Fe53);
        _register(0x61fc83AD0743fEe0ca0b98ABA94a7A9D0E50718a, 0x8A85c533693a87837380d9225d226e334663d104);

        _register(0x5F4113BFCD43307d2382D968327231351b58A5E4, 0x59b2bbE84dD4566D93e1D344c06D5f17CBfdb073);
        _register(0x5F4113BFCD43307d2382D968327231351b58A5E4, 0x63fAFE750b2bA064099195a0c01AB52880520d5D);

        _register(0x024e0b8E22743d89E0465D30C337F951918705fa, 0x53cb6a0B87F0c438d033C59Ad757f6536564db28);

        _register(0x47a1147115756883038d000e526A4186902119e0, 0xd34a20E69403aa10913dd91455aEe574f7611527);

        _register(0x8818518F5250ed3Dc7BCF4E539f6B35b54E29b29, 0x014B5Bb2F3800637e0E7DE077A9af4803AB81E9C);

        _register(0xc97C55442099a325ED7b399925846b51d60eaD3B, 0x43234e1a1c49023725Af693B6bC5a76C11C46765);

        _register(0xCee382F4fF237942366a811D9ED596850E46A050, 0x96BAd93F26C64E72F7B22e3Dee731CA51e84c78b);
        _register(0xCee382F4fF237942366a811D9ED596850E46A050, 0x12ee88A73aB1d6609863f6C863Fc26b017627542);

        _register(0x29CBccD01D8d2d3A4f4C437c4Ae5039362DF95e2, 0x6782F058b8Cc66625c9dA50137cC71730bde1c08);
        _register(0x29CBccD01D8d2d3A4f4C437c4Ae5039362DF95e2, 0xf1a51ea68ACEfC4395B5bC12a8c5d94F4d1a2470);
        _register(0x29CBccD01D8d2d3A4f4C437c4Ae5039362DF95e2, 0x22719197Dd5b49C4bCe447230dC70F77E74020Bc);

        _register(0x89CbF332571F54E2D1CEAdDC2B91b6A96f21df00, 0x0730509FaC1c163E947c26cFa8a40FE76CC846d4);

        _register(0xDcF8023f18409005207026DE7F0D1e780A94F742, 0x5aDEd2a2748e0dda11D5Abbb0d423a94B828a5f0);
        _register(0xDcF8023f18409005207026DE7F0D1e780A94F742, 0x5176fE6b79a153beba945f1BA0fb2FDF4F6a8dEe);
        _register(0xDcF8023f18409005207026DE7F0D1e780A94F742, 0xb7d0fA0669730E46F9faE6D3a89BC26832B55DfE);
        _register(0xDcF8023f18409005207026DE7F0D1e780A94F742, 0x1Eee9A2dB92C46EAfF06B3C31E34db7BD1ECDdaF);

        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x14E989718C622E6A90531C515BF2C9ac5Fb8d713);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x5DcE7412dAC1860B1c9EaCEaE3a09eD2F4eC7600);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x6DB0ba283092dbb17e30639193dbf67091d16ad0);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x9944aC84145836C679acA9968992E12A9330Ed2c);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0xE67d86886f97daF5F059e876A4c3C04a514B3e69);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x0495e62e568d477c10De7116c8938350e2da690E);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x53dacCeC0FDa34C30F89cd64ad29A9BBe84d275E);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0x58eD012303334209F945219fc00F707c0E2C5d80);
        _register(0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8, 0xB07a67678baB935C2cE60edC41463aA5785E9Dd4);

        _register(0x330Da067eA9b7B4dD5f640CF3812Fe3F1212c2C4, 0x5620Df18BaA8fB97E809f05b3D59f9641C964ED0);

        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x072A9B89F4462d3c2F9183e82027b42299B74fD9);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0xd0A26322aBFaA561DA11713e76AF4e5611B9A4fd);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x330Da067eA9b7B4dD5f640CF3812Fe3F1212c2C4);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x91e0c71217225a4870a6eF35a7cA0B674941A746);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x899530F3464A37920674B536384c299C6a09EeeE);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x48e36BdBBc54219136FDd20685ccC73166Fe8324);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0xCa9E4ec800b85345b186dCdA5C02671A861dC067);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x234cc5b3C115E25Efc9E3b9C5bC8Bfc6B69cB5E6);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0xFc6D028371e3eCED057f7B8A8A57f7C68ad306D4);
        _register(0x0730509FaC1c163E947c26cFa8a40FE76CC846d4, 0x21A7619492f3D5aa58345556863026bBa112Db56);

        _register(0xAaF4394aFBe1B7c6c8379DA08a999dA788a9728C, 0x0441Fd8f6b6A9FeE71015F5E90a564Bf79d39052);

        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x994b046DeB3d24B5B242D4ee07D00e1Fed3f3261);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0xc6A3EE287edFce5bdeF89121359fA63b50CB9cAB);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x36917bc886E619521D76F8994DB962Fc1E748E99);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x503C2c166b9A2785Fa944d6D46b0247b1d1A5e8d);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x19347a84d4550E29623ccA6e641cCb6e65Fb9BBA);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0xeb87C91742dA3AdB33C8f0faF0c0111f1Bdb6B1a);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0xADC0B7a58ba5FBD9E8a6980350B39c52704a2f6A);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0xEf4aF552B493Cd52cA79765Ac29098E5b65c3989);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0xc691c060ebEeaB5655cC997246A962E7162e1e8e);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x8702ffdd9E3495A0BF81EB315f966284d41FB594);
        _register(0x6a7405cb055669Af15d14392eD3ce4D330fd2CB5, 0x41224E44922d2d98aa6360c705772c59AAceC96B);

        _register(0x7412C8B906815C25C9031b8B3B9F4805015aC7f2, 0xe674661FDb5bcA205752EA96F7D7Dca631a006C0);

        _register(0xADC0B7a58ba5FBD9E8a6980350B39c52704a2f6A, 0x2009D4cffE6Ef87ea0019FeF3EdC62Ffd211731D);

        _register(0xC555Acf73A1164f7F2eEe5E7F59FEE502F17AFec, 0xeC14389807f0B6499a032DB73FD8a94c1204a216);

        _register(0x234cc5b3C115E25Efc9E3b9C5bC8Bfc6B69cB5E6, 0xEBaCBa195aCcc94E6AC9B34207F3916C41119329);

        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x9BAADCCBB7E843d3e4272cd74EE399c0c00f9954);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0xa23344184E2c6E1aa744E9B7Cd4b513CEa5aFB3c);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x70d79418A686eE65a449C2d06220E643155f0f14);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0xeE5caE74e334C2F1af65d19052b202c2F6bD4aB4);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0xf2869C98fB3D1753346449B06c18F27dc6611292);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x982C8f4e601a63346b7BD0BEDE7C04e139e4f7BD);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x26BC99a54c290a7865DCbF0B1ed8A4f013Ea964f);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x89728067216ca54361060316d766bf681853E7Fa);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x111484d3345848F43c226995174cda275E9D1D5c);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x7E0d4C8Aa8bA9e422cD4414C5e0a9e720d4D2d46);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x767868f8Bf31973CA8f7559E5EA2cb17537003C5);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x68c950840858347b7F744f7C5926657e37Fb4392);
        _register(0x6C0B439b0f993202EdA0A0496C4da8D23aD7C801, 0x5159F99d35Cb74796dE5664Da456b79a21ac5449);

        _register(0xe7e25b26d7d16689a4Ba3f5410B85e30bd297D39, 0x2E0F459670Aa7119eD44dA8B8358eb81B372BA3c);

        _register(0x503C2c166b9A2785Fa944d6D46b0247b1d1A5e8d, 0x1E8c82755F62081Cc7c760730677C5776Da27C32);

        _register(0xdc9E7a6A086DbB784C7BD7d84B4884B0EA1F168A, 0x093ff2FB6B3C815FF955248519ec7B7AF42E665E);

        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0xfAd9Ca41589B3657d56e1a6b38601dCbc5dAb508);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0x8D24E10d251A575cEbe15A18c8f2E9e956F57b60);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0x04559347C9c78805CB65f6b290c0F6FB9FD2C3fD);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0xDcF8023f18409005207026DE7F0D1e780A94F742);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0xEa24C5B3B0F9c0B5bb93d6A72747c385a87aCa7B);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0x08fc58b846e69b332D6De7FaCBA6062648490E8D);
        _register(0x78Da7fCa531d4B6710d616cDD63D77Bc80e7fD32, 0x91C62Ff6e40b9718Af781148fac9D3B6684a4c24);

        _register(0x19347a84d4550E29623ccA6e641cCb6e65Fb9BBA, 0xF4245A2ca2faA8F21DbDA9aaF8213b45a8fF008c);
        _register(0x19347a84d4550E29623ccA6e641cCb6e65Fb9BBA, 0x93967805fAa6eabe9de62D578B1f076863908133);

        _register(0xdAaB7eB7171aAcD568127E246dE64e28b4C6296E, 0x3f947d3fD2eF078f77CF01f781A7392979dFf02e);

        _register(0x8b832f9201651e5F193f004997cCb507a19E2700, 0x12cBBf890b773fC9c4990aa3c3333267c14DD9F8);

        _register(0x17809259208A66d81E94B45c7014f791AAcBbB0d, 0x559bc75eC6e6AB2079421BbD0ebecAd729a60FB2);

        _register(0x8A85c533693a87837380d9225d226e334663d104, 0x2069fE5c5bEAf44DB81AED0a281512e40d3F809b);
        _register(0x8A85c533693a87837380d9225d226e334663d104, 0xE5756aA82A39d3E23Dbc4831A8c6a6840b1663C2);
        _register(0x8A85c533693a87837380d9225d226e334663d104, 0xe8b9F63bb91ed1a2ab7d8A5073a5FAf45c63340F);

        _register(0x3023138Cb3AEeAe67c4033015a39b56aF582E3Fc, 0x17809259208A66d81E94B45c7014f791AAcBbB0d);

        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0x61229A2Ac51B2430d228F58A2658E1770346F0f6);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0xC531E47F882A34543Cc77E92FFbba93D3Ea11117);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0xb2E9113d7Ac34f7D39662b0e8Ddc769BDec9cbF7);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0x3023138Cb3AEeAe67c4033015a39b56aF582E3Fc);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0x7be8c96A98CB2FE2Fd6C59edd2a83CeBb3233bA2);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0x871D583DEB3083993b28487bEb934EEf155E0118);
        _register(0x0DAb09FFe73b6282D8B38479d6FC0472Ed16118a, 0x78a607231617D6E0e3719ed3e127e5084f6CB1b6);

        _register(0xeb87C91742dA3AdB33C8f0faF0c0111f1Bdb6B1a, 0x2AA4782C4CD8F26116B753016d3D789C45c077dc);

        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0x25B78d4f814f12C6B2e1D87b28A56143e5322bE4);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0xF47AC69c3F6b7A2950523E641F09C80A0559D8e7);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0x4877f396950C4c93DCF29AB78F5a246548AAf40E);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0xc2DC0add26ee49fAbf8E2908B9D5e0991317f922);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0x6890eEf74Ea683a9383B6A32099b3967EAe7907E);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0x0e6ce52C1D0257808be60C3f799172Bd1Ad30028);
        _register(0x02714DAeBe7EC7C7803E6C2F5Ac18814dAe21BFe, 0x612772eC0968C7bf79856ca3288ef383Ec90Da9d);

        _register(0x405481f2d0031115a14e3E3af0283cae429D93Fb, 0x72F72E91F658ACFa46d6B6F2bF58dDD85193EC71);

        _register(0x27370b2f0D172dA1d506Fa42EFB4a71fC03F99Af, 0x47a1147115756883038d000e526A4186902119e0);
        _register(0x27370b2f0D172dA1d506Fa42EFB4a71fC03F99Af, 0x632d80122AD73dC56CF7429dD038B514C25F32b3);
        _register(0x27370b2f0D172dA1d506Fa42EFB4a71fC03F99Af, 0xf6e03430B73670dc1BDdC2520Bebf08b3a79fe47);

        _register(0x6890eEf74Ea683a9383B6A32099b3967EAe7907E, 0xc3646C9f183A7Ff16aDdB0B778221519a1FAEaC4);

        _register(0x93967805fAa6eabe9de62D578B1f076863908133, 0xe53B3CB82815B613062DC657A9FCd6cb77eC595A);
        _register(0x93967805fAa6eabe9de62D578B1f076863908133, 0x172aa24dCAEFcB2Ef14104761d37233ca6E6c166);
        _register(0x93967805fAa6eabe9de62D578B1f076863908133, 0x423bdfeB5D25b0C8d5c6Ff598e99EB883A340381);

        _register(0x48e36BdBBc54219136FDd20685ccC73166Fe8324, 0xAaF4394aFBe1B7c6c8379DA08a999dA788a9728C);
    }
}