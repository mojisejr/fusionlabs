import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/uLt7UG2JOQRZKuvuhG-ARE-7_2i5oTXA",
      accounts: [process.env.wallet!],
    },
    bitkub_testnet: {
      url: "https://rpc-testnet.bitkubchain.io",
      accounts: [process.env.wallet!],
    },
    mumbai_testnet: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.wallet!],
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 3000,
      },
    },
  },
  etherscan: {
    // apiKey: "23Y6847UATWJXN3ZUJAYTJFRR4H64HXKXD",
    apiKey: "PX1UPAJSMHJPBT8N6GWIUXQZCE26TFPMU3",
  },
  gasReporter: {
    enabled: true,
    currency: "THB",
    gasPriceApi:
      "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
  },
};

export default config;
