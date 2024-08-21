require("@nomiclabs/hardhat-waffle");
require("hardhat-abi-exporter");
require("dotenv").config({ path: __dirname + "/.env" });
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
      },
    ],
  },

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
      gasPrice: "auto",
    },

    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 21000000000,
      accounts: [`0x${process.env.privateKey}`],
    },

    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API}`,
      accounts: [`0x${process.env.privateKey}`],
    },
  },
};
