import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.RINKEBY_PRIVATE_KEY || ""],
    },
    // ethereum
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.MAINNET_PRIVATE_KEY || ""],
    },
    // bsc
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [process.env.BSC_TESTNET_PRIVATE_KEY || ""],
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org",
      chainId: 56,
      accounts: [process.env.BSC_MAINNET_PRIVATE_KEY || ""],
    },
    // polygon
    matic_testnet: {
      url: "https://rpc-mumbai.matic.today", // replace it with your own
      chainId: 80001,
      accounts: [process.env.MATIC_TESTNET_PRIVATE_KEY || ""],
    },
    matic_mainnet: {
      url: "https://rpc-mainnet.maticvigil.com", // replace it with your own
      chainId: 137,
      accounts: [process.env.MATIC_MAINNET_PRIVATE_KEY || ""],
    },
    // avalanche
    avalanche_mainnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: [process.env.AVALANCHE_MAINNET_PRIVATE_KEY || ""],
    },
    // fantom
    fantom_mainnet: {
      url: "https://rpc.ftm.tools/",
      chainId: 250,
      accounts: [process.env.FANTOM_MAINNET_PRIVATE_KEY || ""],
    },
    // arbitrum
    arbitrum_mainnet: {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: [process.env.ARBITRUM_MAINNET_PRIVATE_KEY || ""],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./build/cache",
    artifacts: "./build/artifacts",
  },
};

export default config;
