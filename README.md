Token Deployment on Binance Smart Chain (BSC) using Hardhat
This repository contains the necessary code and instructions for deploying an ERC20 token on the Binance Smart Chain (BSC) using the Hardhat development environment. Follow the steps below to deploy your token.



Prerequisites
Before you begin, ensure you have the following installed:


Node.js (version 14.x or later)
Hardhat
Metamask (for interacting with BSC)
BSC Testnet or Mainnet RPC URL
Setup
Clone this repository:


https://github.com/MohsinAliSolangi/CreedCoin
Install dependencies:


cd your-repo
npm install
Configure your Hardhat create ENV File and set Variable valuse of hardhat config file


module.exports = {
  solidity: "0.8.0",
  networks: {
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: { mnemonic: "your testnet wallet mnemonic" }
    },
    bscMainnet: {
      url: "https://bsc-dataseed1.binance.org/",
      accounts: { mnemonic: "your mainnet wallet mnemonic" }
    }
  }
};



Deployment
Compile your contracts:



npx hardhat compile
Deploy your token to the BSC Testnet or Mainnet:




npx hardhat run scripts/deploy.js --network bscTestnet
or

npx hardhat run scripts/deploy.js --network bscMainnet
Confirm the deployment transaction in Metamask.


Verify the deployed contract address and token details.

Usage
You can now use your deployed token on the Binance Smart Chain. Use the contract address to interact with the token in your DApp or other applications.