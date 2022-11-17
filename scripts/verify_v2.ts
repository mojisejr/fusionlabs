import { run } from "hardhat";

async function main() {
  const { host, stimulus, labs, mutant } = {
    host: "0x0d9Ee5a76c822e08af772A50FBA6b23ee2CBB701",
    stimulus: "0xF175824E57Ab1C1cc420C7d406C0778209e12dFE",
    labs: "0x41f84B07F827B38AF5039EC393e60A8bE6ACC3c8",
    mutant: "0x82b6EfFCA535c4264A725AB5a1bf9958D303dC91",
  };

  // verify Contracts
  console.log("Host verifing =>  ", host);
  await run("verify:verify", {
    address: host,
    contract: "contracts/Host.sol:Host",
  });

  console.log("Stimulus verifing =>  ", stimulus);
  await run("verify:verify", {
    address: stimulus,
    contract: "contracts/Stimulus.sol:Stimulus",
  });

  // console.log("Labs verifying => ", labs);
  // await run("verify:verify", {
  //   address: labs,
  //   contract: "contracts/v2/FusionLabsV2.sol:FusionLabsV2",
  //   constructorArguments: [host, stimulus, mutant, 1000],
  // });

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

// host: "0x6E9f9ba6ABBe0Fb7E2f88Bd43e91a78949b4719c",
// stimulus: "0xb01fCF558c3EC204e21E303267669254d7eea4BC",
// labs: "0x5ADCDB93B38CB675EE31f07AbB8b07630b100480",
// mutant: "0xC5D459f6f219A73eB7e6087A344B9CbCd91d743C",
