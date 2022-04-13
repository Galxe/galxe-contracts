import * as dotenv from "dotenv";
import { ethers } from "hardhat";

dotenv.config();

async function main() {
  const galaxySigner = process.env.GALAXY_SIGNER;
  const campaignSetter = process.env.CAMPAIGN_SETTER;
  const contractOwner = process.env.CONTRACT_OWNER;
  const treasureManager = process.env.TREASURE_MANAGER;

  if (
    galaxySigner === "" ||
    campaignSetter === "" ||
    contractOwner === "" ||
    treasureManager === ""
  ) {
    throw new Error("Missing environment variables");
  }

  // We get the contract to deploy
  const SpaceStationV2 = await ethers.getContractFactory("SpaceStationV2");
  const sss = await SpaceStationV2.deploy(
    galaxySigner,
    campaignSetter,
    contractOwner,
    treasureManager
  );

  await sss.deployed();

  console.log("SpaceStationV2 deployed to:", sss.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
