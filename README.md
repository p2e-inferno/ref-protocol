# Ref Protocol - Decentralized Affiliate Marketing

## Description

Ref Protocol is a decentralized affiliate marketing platform built on the Ethereum blockchain. This DApp enables users to create unique campaigns and allows affiliates to earn through these campaigns.

This DApp is centered around providing flexibility to campaign creators and affiliates. Creators can set up their campaigns complete with commission rates while affiliates can join these campaigns to generate earnings.  

Affiliates have the option to directly drive sales or expand their network by recruiting additional affiliates. All the earnings within the platform can be withdrawn via the 'WithdrawalFacet' part of the DApp.

## Getting Started

### For Creators:

- Define a unique campaign including crucial details such as commission rate and campaign rules.
- Deploy your campaign by calling the `createCampaign()` function.
- The `onKeyPurchase()` function enables tracking of all purchases made within your campaign.
- Your campaign is now live and accessible for affiliates to join. 

### For Affiliates:

- Scan through the live campaigns and join the desired one.
- Call the `becomeAffiliate()` function with required parameters (reffererAddress, campaignId).
- After successful execution, share the referral links to start earning commissions on purchases via your link.
- Once you've generated commissions, leverage the `WithdrawalFacet` to conveniently withdraw your earnings.

The Ref Protocol platform is a great way to step into the world of decentralized Universal Basic Income (UBI) systems.

For entreprenuers, creators, event organizers, community builders, and the crypto dreamers. 

## ⚙️ Built using 🏗 Scaffold-ETH 2


- ✅ **Contract Hot Reload**: Your frontend auto-adapts to your smart contract as you edit it.
- 🪝 **[Custom hooks](https://docs.scaffoldeth.io/hooks/)**: Collection of React hooks wrapper around [wagmi](https://wagmi.sh/) to simplify interactions with smart contracts with typescript autocompletion.
- 🧱 [**Components**](https://docs.scaffoldeth.io/components/): Collection of common web3 components to quickly build your frontend.
- 🔥 **Burner Wallet & Local Faucet**: Quickly test your application with a burner wallet and local faucet.
- 🔐 **Integration with Wallet Providers**: Connect to different wallet providers and interact with the Ethereum network.

![Debug Contracts tab](https://github.com/scaffold-eth/scaffold-eth-2/assets/55535804/1171422a-0ce4-4203-bcd4-d2d1941d198b)

## Requirements

Before you begin, you need to install the following tools:

- [Node (v18 LTS)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Clone this repo & install dependencies

```
git clone https://github.com/blahkheart/ref-protocol
cd ref-protocol
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Hardhat. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `hardhat.config.ts`.

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/hardhat/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/hardhat/deploy` to deploy the contract to the network. You can also customize the deploy script.

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the `Debug Contracts` page. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

Run smart contract test with `yarn hardhat:test`

- Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`
- Edit your frontend in `packages/nextjs/pages`
- Edit your deployment scripts in `packages/hardhat/deploy`

## Documentation

Visit our [docs](https://docs.scaffoldeth.io) to learn how to start building with Scaffold-ETH 2.

To know more about its features, check out our [website](https://scaffoldeth.io).

## Contributing to Scaffold-ETH 2

We welcome contributions to Scaffold-ETH 2!

Please see [CONTRIBUTING.MD](https://github.com/scaffold-eth/scaffold-eth-2/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scaffold-ETH 2.


0x3908deE0088ed2e8d696Aa61863375A9F3659f7A