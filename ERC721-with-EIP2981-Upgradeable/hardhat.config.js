require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: process.env.NETWORK,
  networks: {
    hardhat: {
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/1lSStfXOLEyEyFq2jfdgJByjUE4nUD0K",
      accounts: [process.env.PRIVATE_KEY]
    },
    matic: {
      url: "https://rpc-mainnet.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
};