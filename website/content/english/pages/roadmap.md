---
title: "Roadmap"
meta_title: "Roadmap of the future updates of LegitDAO"
description: "This is the roadmap of the future updated of LegitDAO"
draft: false
---
{{< toc >}}

LegitDAO is embarking on an exciting journey toward creating a decentralized autonomous organization (DAO) with a robust ecosystem. Our roadmap outlines the steps we will take to develop essential components that will enable users to claim tokens, utilize smart contracts, and foster community engagement. In this article, we will elaborate on our plans, breaking them down into distinct phases to make our vision clearer and more accessible.

## Milestone Deadline
Our objective is to finalize the alpha version of this first phase within four (4) to six (6) months. As we complete each section, we will push the code to our GitHub repository. Additionally, we will update the [changelog](/changelog) and publish a [blog post](/blog) detailing our development process.

## Token Claiming and Smart Contracts
In our next update, we will introduce the mechanism for individuals to claim their tokens within the LegitDAO ecosystem. These tokens will leverage smart contracts built on the BNB Chain, ensuring secure and efficient transactions. To facilitate this, we will create three primary smart contracts: Founder, DAO, and Currency. Each contract will serve a unique purpose, contributing to the overall functionality of the ecosystem.

Additionally, we will develop an Affiliate smart contract that will empower users to refer others to our project. This feature will include the initial deployment of the Affiliate smart contract, allowing for a tradable referral tree that can reward those who contribute to our community’s growth. This innovative approach not only encourages engagement but also builds a supportive environment for all participants.

## Developing the Bytecode Interpreter
Following the establishment of our token framework, we will focus on creating a bytecode interpreter. This crucial component will execute logic within our ecosystem, utilizing unsigned integers to understand commands. The bytecode interpreter will serve as the backbone for future functionalities, allowing us to process commands efficiently and accurately.

## Grammar Matcher and Abstract Syntax Tree (AST)
Next, we will introduce a grammar matcher that will facilitate the creation of an Abstract Syntax Tree (AST) based on grammar schemas and input data. This step is essential for parsing and understanding the structures we will encounter within our ecosystem.

Following the implementation of the grammar matcher, we will develop a selector. The selector will utilize schema definitions to fetch data from the AST easily. By employing these tools, we aim to streamline data retrieval processes, enhancing the overall efficiency of our ecosystem.

## Virtual Machine Development
To take our functionality further, we will create a virtual machine (VM) grammar. This VM will be built using the grammar matcher and selector, allowing for efficient parsing of input grammar into bytecode. This bytecode will then be interpreted by our bytecode interpreter, enabling dynamic execution of commands.

## Graph Database System
The next major component of our roadmap involves creating a graph database system. This database will leverage grammar to establish links and connections between various data points. By parsing instructions with our grammar matcher and fetching relevant data using the selector, we will compile these instructions into bytecode for interpretation.

As part of this phase, we will modify the bytecode interpreter to allow for atomic writing of data on disk. This enhancement will facilitate the implementation of a transaction system that accurately represents the database’s state. Users will have the ability to navigate the various states of the database, retrieving data as needed.

## Custom Blockchain
To support our currency, we will develop a blockchain that will also hold currency tied to our Currency smart contract on the BNB Chain. Each transaction on this blockchain will incorporate a 64-byte hash representing instruction bytes that our bytecode interpreter can interpret. Moreover, we will create a bridge between this blockchain and the BNB Chain to ensure atomic transfers, providing seamless interaction between the two networks.

## NFT Marketplace Development
In tandem with the graph database, we will establish a code NFT marketplace. This marketplace will utilize our graph database for storage and our blockchain for minting new NFTs. Users will be able to buy and sell NFTs using the currency associated with this blockchain, fostering an interactive community space.

As we develop our bytecode interpreter further, we will introduce vector operations. By updating our virtual machine to accommodate new instructions, we can implement functionality that matches similar vectors within our graph database. This will cultivate a community of miners responsible for processing data, creating hash trees, and establishing connections between similar data points.

## Content Database and Language Model
Our roadmap also includes the creation of a multilingual content database. This database will allow for the submission, filtering, and moderation of content by our community, ensuring high-quality standards. Miners will have the opportunity to process this data, creating meaningful links that contribute to the development of a large language model (LLM) and an efficient language translator.

To enhance our capabilities further, we will develop a transpiling system. This system will use specific transpiling schemas to convert various data inputs into usable formats. By utilizing our grammar matcher to validate input structure and the selector for data retrieval, we will enable complex queries against our graph database or generate bytecode for interpretation.

## Decentralized Platform for Data Interaction
Ultimately, we aim to create a decentralized platform that leverages the technologies developed throughout this roadmap. This platform will facilitate the submission, filtering, classification, and moderation of data. By creating a vast public database of interconnected information, we will empower users to interact with the data easily through our large language model, enhancing accessibility and engagement within our community.

## Clients Onboarding
We will use the same technology from our decentralized data platform to help companies manage their data effectively. With our system, they can organize their data with public, secret, and private roles and permissions. Once set up, we can offer cloud data hosting services to these clients using our own currency.

Additionally, companies will have the option to connect their databases to our public data platform, and they can pay for these services with our decentralized currency. To encourage more users, people who refer customers to our platform will earn a share of the revenue based on what those customers spend.

## Conclusion
The roadmap for LegitDAO is a comprehensive plan designed to build a decentralized ecosystem that fosters collaboration, innovation, and transparency. Each phase of development is intricately linked, ensuring that we create a robust foundation for the future of artificial general intelligence (AGI). By leveraging community involvement, open-source principles, and cutting-edge technology, LegitDAO is poised to transform how we interact with AI and the digital world. As we progress, we invite you to join us on this exciting journey, contributing your ideas and expertise to make our vision a reality.