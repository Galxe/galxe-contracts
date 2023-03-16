import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, toUtf8Bytes } from "ethers";

const name = "SpaceBalance";

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer, spaceBalanceOwner, spaceBalanceTreasurer } =
    await getNamedAccounts();

  console.log("deployer: %s", deployer);
  if (
    !ethers.isAddress(spaceBalanceOwner) ||
    !ethers.isAddress(spaceBalanceTreasurer)
  ) {
    throw new Error("invalid owner or treasurer");
  }

  const c = await deploy(name, {
    from: deployer,
    args: [deployer],
    log: true,
    deterministicDeployment: ethers.keccak256(toUtf8Bytes(name)),
  });
  console.log("deployed contract %s", c.address);

  console.log("initializing contract...");
  console.log("owner: %s", spaceBalanceOwner);
  console.log("treasurer: %s", spaceBalanceTreasurer);
  const receipt = await deployments.execute(
    name,
    {
      from: deployer,
    },
    "initialize",
    spaceBalanceOwner,
    spaceBalanceTreasurer
  );

  console.log("initialized contract with tx %s", receipt.transactionHash);
};

deploy.tags = [name];
export default deploy;
