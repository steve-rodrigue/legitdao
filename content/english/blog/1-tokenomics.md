---
title: "Tokenomics of the LegitDAO ecosystem"
meta_title: "Tokenomics of the LegitDAO ecosystem"
description: "This blog post explains the tokenomics of the LegitDAO ecosystem"
date: 2024-10-19T05:00:00Z
image: "/images/blogs/tokenonomics.png"
categories: ["Tokenomics"]
author: "Steve Rodrigue"
tags: ["tokenomics", "smart-contracts"]
draft: false
---
In the world of decentralized organizations, the structure and governance of the system play a pivotal role in its success. LegitDAO, a decentralized autonomous organization (DAO), comprises several essential components, including the founding members, the affiliate network, and the DAO smart contract itself. This article delves into each of these elements, outlining their functions, interactions, and contributions to the overall ecosystem. 

## Founders
The founders of LegitDAO are the driving force behind the organization, responsible for bringing the project to life. These individuals not only initiated the concept but also provided the necessary resources to launch the DAO successfully. Their roles included planning the initial development of the technology, establishing the tokenomics, and promoting the venture to build the first community of LegitDAO supporters.

Within the LegitDAO framework, there are six founding members, each possessing a significant stake in the organization. They will hold 16,666,666 tokens each, contributing to a total cap of 99,999,996 tokens for the smart contract. This structure allows for a controlled distribution of tokens and creates a marketplace where founders can sell their tokens to the community in exchange for BNB coins. An interesting aspect of this marketplace is that there is no tax on trading the founder's units, making it an attractive option for initial investors.

## Affiliate Program
The affiliate program within LegitDAO is designed to encourage community growth by rewarding individuals who refer new members to the platform. This smart contract allows users to register their wallets and build a multi-level affiliate tree, enhancing the overall reach of the DAO.

Initially, referrals came from friends and family during the planning phase, leading to the formation of a community of approximately 300 members. Each time someone is referred, they also become part of the referring individual's affiliate network, enabling the creation of a multi-tiered structure. The affiliate program features a marketplace where users can buy and sell their affiliate trees in exchange for BNB coins. Importantly, there are no fees for trading affiliate trees, promoting a collaborative and engaging environment.

## DAO Smart Contract
The DAO smart contract is an ERC-20 compliant contract with additional capabilities tailored for LegitDAO. It holds tokens assigned to community members, particularly the friends and family of the founders. When individuals contribute to the DAO, they are rewarded with tokens proportional to their contribution.

For example, if a member contributes $2,000, they will receive a calculated amount of DAO tokens based on the total contributions. Importantly, 15% of each contribution is allocated to the referral tree that brought them into the DAO. During the planning phase, LegitDAO accumulated a total of CAD 1.6 million in contributions, safely stored in Bitcoin until the project launch. Once the DAO smart contract is deployed, these funds will be converted to BNB coins and managed by the community.

### Real-world Example
To illustrate how the contribution system works, consider the following scenario. The DAO has accumulated CAD 1.6 million, and the total token supply is 115 million. 

- Jack contributes $2,000 and refers Anna, who contributes $1, and then Anna refers Johnny, who contributes $1,000.
- Jack would receive 125,000 tokens for his contribution.
- Anna would receive 62 tokens for her contribution.
- Johnny would receive 62,500 tokens for his contribution.
- Additionally, Anna would earn 9,375 tokens for referring Johnny.
- Jack would also earn tokens for referring Anna and Johnny.

In total, the distribution of tokens would be as follows:
- Jack would have 126,415 tokens.
- Anna would have 9,437 tokens.
- Johnny would receive 62,000 tokens.

### Token Minting
The DAO contract is designed to mint 100% of its tokens upon deployment. No additional tokens will be created in the future, ensuring that the total supply remains fixed.

### Marketplace in the DAO Smart Contract
The DAO smart contract includes a marketplace feature that enables users to buy and sell tokens using BNB coins. This creates an active trading environment, facilitating liquidity within the DAO ecosystem.

### Transfer Tax
When transferring DAO tokens, whether through sales in the marketplace or direct wallet transfers, a tax is applied. There is a 20% tax when initiating a transfer and a 15% tax when receiving tokens. These fees are distributed to the individuals who referred the buyer and seller. If a transfer occurs without a referral, the fees will go to the founding member contract.

## Service-Provider Smart Contract
The service-provider smart contract is developed specifically for those who wish to propose services to the DAO. Each service provider must deploy their own contract and connect it to the proposal smart contract to be eligible for executing contracts with the DAO.

This ERC-20 compliant contract allows for open management of developers and tasks, fostering transparency. The DAO can track what tasks have been executed by each developer, ensuring accountability and clarity in the project.

### Transfer Tax
The service-provider contract includes a transfer tax of 0.25% for both the sender and receiver of tokens. These fees are directed to the affiliate tree that referred the service provider. If no referral exists, the fees go to the founding member contract.

## Developer Smart Contract
The developer smart contract represents the first service provider in the LegitDAO ecosystem. This developer conducted the initial research and development for the project, creating essential code that will be integrated into the ecosystem. The contract utilizes the service-provider smart contract code for effective management.

## Currency
The currency used within LegitDAO is an ERC-20 smart contract that contains a total supply of 100 million tokens. At launch, 200,000 tokens will be allocated to the developer's smart contract, while the remaining tokens will be available for sale in exchange for BNB coins. The initial price will start at 0.00001 BNB.

Each time a token is sold, the price of the next token will double, creating a dynamic pricing structure.

The currency smart contract will distribute 80% of the BNB accumulated to the developer's smart contract, while 5% will be allocated to the DAO and 15% will serve as referral payments. If the buyer was referred by someone, the referral payment will go to that referral tree. If not, it will be sent to the founder's smart contract.

### Transfer Tax
Every time a transfer occurs, a transfer tax of 0.25% will be paid by the sender and another 0.25% by the receiver. These fees will be directed to the developer smart contract.

### Marketplace
The currency smart contract also includes a marketplace feature, enabling users to buy and sell tokens for BNB coins, facilitating market activity.

## Proposition
The proposition smart contract does not contain currency; instead, it allows service providers to register as potential proposal writers. The DAO will review and approve or deny service providers based on the quality of their public information.

Once accepted, service providers can submit proposals to the contract. The DAO will then vote to accept or deny these proposals based on their relevance to the organization's mission of developing the necessary tools for artificial general intelligence (AGI).

When a proposal is accepted, service providers can apply to execute the project by providing a price in the DAO's currency and setting a deadline for completion.

The DAO will vote to accept the service provider to execute the proposal. At this point, the currency will be locked in the DAO smart contract.

Upon completion of the proposal by the service provider, the DAO will verify the quality of the work. If successful, the service provider will be paid automatically by the DAO smart contract, and the proposal will be marked as successful. If not, the proposal will be flagged as unsuccessful, and the locked currency will be released back to the DAO contract.