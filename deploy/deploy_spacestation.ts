import * as dotenv from "dotenv";
import { Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  const deployerPk = process.env.PRIVATE_KEY as string;
  const galaxySigner = process.env.GALAXY_SIGNER as string;
  const campaignSetter = process.env.CAMPAIGN_SETTER as string;
  const contractOwner = process.env.CONTRACT_OWNER as string;
  const treasureManager = process.env.TREASURE_MANAGER as string;

  if (
    deployerPk === "" ||
    galaxySigner === "" ||
    campaignSetter === "" ||
    contractOwner === "" ||
    treasureManager === ""
  ) {
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

  console.log("Galxe Signer: ", galaxySigner);
  console.log("Campaign Setter: ", campaignSetter);
  console.log("Contract Owner: ", contractOwner);
  console.log("Treasure Manager: ", treasureManager);

  const SpaceStationV2 = await deployer.loadArtifact("SpaceStationV2");

  const sss = await deployer.deploy(SpaceStationV2, [
    galaxySigner,
    campaignSetter,
    contractOwner,
    treasureManager,
  ]);

  console.log("SpaceStationV2 deployed to:", sss.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
