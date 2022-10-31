import { ethers, run } from "hardhat";
import { getExpectedContractAddress } from "../utils/getExpectedContractAddress";

async function deploy() {
  const hostFac = await ethers.getContractFactory("Host");
  const StimulusFac = await ethers.getContractFactory("Stimulus");
  const mutantFac = await ethers.getContractFactory("Mutant");
  const labsFac = await ethers.getContractFactory("FusionLabs");
  const [owner] = await ethers.getSigners();

  console.log("deploying ...");
  const labsExpectedAddr = await getExpectedContractAddress(owner, 3);
  const host = await hostFac.deploy();
  await host.deployed();
  console.log("host deployed ...");
  const stimulus = await StimulusFac.deploy();
  await stimulus.deployed();
  console.log("stimulus deployed ...");
  const mutant = await mutantFac.deploy(labsExpectedAddr);
  await mutant.deployed();
  console.log("mutant deployed ...");
  const labs = await labsFac.deploy(
    host.address,
    stimulus.address,
    mutant.address,
    1000
  );
  await labs.deployed();
  console.log("labs deployed ...");

  return {
    host: host.address,
    stimulus: stimulus.address,
    mutant: mutant.address,
    labsExpect: labsExpectedAddr,
    labs: labs.address,
  };
}

async function main() {
  // const { host, stimulus, labs, mutant } = await deploy();
  // console.log("deployed addresses: ", { host, stimulus, labs, mutant });
  const { host, stimulus, labs, mutant } = {
    host: "0xFba5De93343cB99d69127c10970be31875a2263a",
    stimulus: "0x3cA7AfA1d2715E1F4bD8a95b7B2780E752855028",
    labs: "0xB5aB626BcaD0e8c09760e9B1d161578b61CaF559",
    mutant: "0x57C7D817A4c3f4dBaEBdef2057CDEd8f5e61Cf44",
  };

  // verify Contracts
  // console.log("Host verifing =>  ", host);
  // await run("verify:verify", {
  //   address: host,
  //   contract: "contracts/Host.sol:Host",
  // });

  console.log("Stimulus verifing =>  ", stimulus);
  await run("verify:verify", {
    address: stimulus,
    contract: "contracts/Stimulus.sol:Stimulus",
  });

  console.log("Labs verifying => ", labs);
  await run("verify:verify", {
    address: labs,
    contract: "contracts/FusionLabs.sol:FusionLabs",
    constructorArguments: [host, stimulus, mutant, 1000],
  });

  console.log("Mutant verifying => ", mutant);
  await run("verify:verify", {
    address: mutant,
    contract: "contracts/Mutant.sol:Mutant",
    constructorArguments: [labs],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
