import * as dotenv from "dotenv";
import { ethers } from "hardhat";

dotenv.config();

async function main() {
  const contractOwner = process.env.CONTRACT_OWNER || "";
  const treasureManager = process.env.TREASURE_MANAGER || "";
  const url = "https://graphigo.prd.galaxy.eco/metadata/";

  if (contractOwner === "" || treasureManager === "") {
    throw new Error("Missing environment variables");
  }

  const StarNFTV3NaiveFactory = await ethers.getContractFactory(
    "StarNFTV3NaiveFactory"
  );
  const snf = await StarNFTV3NaiveFactory.deploy(
    contractOwner,
    treasureManager,
    url
  );

  await snf.deployed();

  console.log("StarNFTV3NaiveFactory deployed to:", snf.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
