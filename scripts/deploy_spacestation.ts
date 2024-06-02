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

  await sss.deployed(0xC1D78db0F5d00110935df8679a9b61dA759F1E04);

  console.log("SpaceStationV2 deployed to:", sss.0xC1D78db0F5d00110935df8679a9b61dA759F1E04);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
