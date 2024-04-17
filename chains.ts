const deployer = process.env.PRIVATE_KEY || "";

export const networks = {
  hardhat: {
    chainId: 31337,
  },
  avalanche: {
    chainId: 43114,
    url: "https://api.avax.network/ext/bc/C/rpc",
    accounts: [deployer],
  },
  bsc: {
    chainId: 56,
    url: "https://bsc-dataseed1.binance.org",
    accounts: [deployer],
  },
  "bsc-testnet": {
    chainId: 97,
    url: "https://rpc.ankr.com/bsc_testnet_chapel",
    accounts: [deployer],
  },
  goerli: {
    chainId: 5,
    url: "https://rpc.ankr.com/eth_goerli",
    accounts: [deployer],
  },
  mainnet: {
    chainId: 1,
    url: "https://mainnet.infura.io/v3/xxxxx",
    accounts: [deployer],
  },
  "polygon-mainnet": {
    chainId: 137,
    url: "https://rpc-mainnet.maticvigil.com",
    accounts: [deployer],
  },
  "polygon-mumbai": {
    chainId: 80001,
    url: "https://rpc-mumbai.maticvigil.com",
    accounts: [deployer],
  },
  sepolia: {
    chainId: 11155111,
    url: "https://sepolia.infura.io/v3/xxxxx",
    accounts: [deployer],
  },
  zkSyncEra: {
    url: "https://mainnet.era.zksync.io",
    chainId: 324,
    ethNetwork: "mainnet",
    zksync: true,
    verifyURL: "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
  },
  "blast-testnet": {
    chainId: 168587773,
    url: "https://sepolia.blast.io",
    accounts: [deployer],
  },
  "blast-mainnet": {
    chainId: 81457,
    url: "https://rpc.blast.io",
    accounts: [deployer],
  },
  "shardeum-sphinx": {
    chainId: 8082,
    url: "https://dev110.shardeum.org/",
    accounts: [deployer],
  },
  "kroma-sepolia": {
    chainId: 2358,
    url: "https://api.sepolia.kroma.network/",
    accounts: [deployer],
  },
  "kroma-mainnet": {
    chainId: 255,
    url: "https://api.kroma.network/",
    accounts: [deployer],
  },
  "zeta-mainnet": {
    chainId: 7000,
    url: "https://zetachain-evm.blockpi.network/v1/rpc/public",
    accounts: [deployer],
  },
  "cronos-mainnet": {
    chainId: 25,
    url: "https://evm.cronos.org",
    accounts: [deployer],
  },
  "zircuit-testnet": {
    chainId: 48899,
    url: "https://zircuit1.p2pify.com",
    accounts: [deployer],
  },
  "zksync-era-sepolia": {
    chainId: 300,
    url: "https://rpc.ankr.com/zksync_era_sepolia",
    accounts: [deployer],
  },
};
