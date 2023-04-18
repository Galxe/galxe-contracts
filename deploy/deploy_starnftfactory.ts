import * as dotenv from "dotenv";
import { Wallet } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  const deployerPk = process.env.PRIVATE_KEY || "";
  const contractOwner = process.env.CONTRACT_OWNER || "";
  const treasureManager = process.env.TREASURE_MANAGER || "";
  const url = "https://graphigo.prd.galaxy.eco/metadata/";

  if (deployerPk === "" || contractOwner === "" || treasureManager === "") {
    throw new Error("Missing environment variables");
  }

  const wallet = new Wallet(deployerPk);
  const deployer = new Deployer(hre, wallet);

  const balance = await deployer.zkWallet.getBalance();

  console.log(
    "Deployer: %s Balance: %s",
    deployer.zkWallet.address.toString(),
    balance.toString()
  );

  console.log("Contract Owner: ", contractOwner);
  console.log("Treasure Manager: ", treasureManager);

  const StarNFTV4NaiveFactory = await deployer.loadArtifact(
    "StarNFTV4NaiveFactory"
  );

  const snf = await deployer.deploy(StarNFTV4NaiveFactory, [
    contractOwner,
    treasureManager,
    url,
  ]);

  console.log("StarNFTV4NaiveFactory deployed to:", snf.address);
}
