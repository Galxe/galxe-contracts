import { HardhatUserConfig, HttpNetworkUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "hardhat-deploy";
import { ethers } from "ethers";

import dotenv from "dotenv";
dotenv.config();
const {
  DEPLOYER_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
  ALCHEMY_KEY,
  SPACE_BALANCE_OWNER,
  SPACE_BALANCE_TREASURER,
} = process.env;

const sharedNetworkConfig: HttpNetworkUserConfig = {
  accounts: [DEPLOYER_PRIVATE_KEY!],
};
const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY!);

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
        version: "0.8.9",
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
    // ethereum
    mainnet: {
      ...sharedNetworkConfig,
      url: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
    },
    goerli: {
      ...sharedNetworkConfig,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_KEY}`,
      chainId: 5,
    },
    // bsc
    bsc_testnet: {
      ...sharedNetworkConfig,
      url: "https://rpc.ankr.com/bsc_testnet_chapel",
      chainId: 97,
    },
    bsc_mainnet: {
      ...sharedNetworkConfig,
      url: "https://rpc.ankr.com/bsc",
      chainId: 56,
    },
    // polygon
    matic_testnet: {
      ...sharedNetworkConfig,
      url: "https://rpc.ankr.com/polygon_mumbai",
      chainId: 80001,
    },
    matic_mainnet: {
      ...sharedNetworkConfig,
      url: "https://rpc.ankr.com/polygon",
      chainId: 137,
    },
    // avalanche
    avalanche_mainnet: {
      ...sharedNetworkConfig,
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
    },
    // fantom
    fantom_mainnet: {
      ...sharedNetworkConfig,
      url: "https://rpc.ftm.tools/",
      chainId: 250,
    },
    // arbitrum
    arbitrum_mainnet: {
      ...sharedNetworkConfig,
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
    },
  },
  namedAccounts: {
    // Shared Galxe deployer
    deployer: deployer.address,

    // SpaceBalance contract
    spaceBalanceOwner: SPACE_BALANCE_OWNER || "",
    spaceBalanceTreasurer: SPACE_BALANCE_TREASURER || "",
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "contracts",
    deploy: "src/deploy",
    tests: "test",
    cache: "build/cache",
    artifacts: "build/artifacts",
  },
};

export default config;
