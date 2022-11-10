import { expect } from "chai";
import { ethers } from "hardhat";
import { getExpectedContractAddress } from "../utils/getExpectedContractAddress";

describe("Labs Tests", async () => {
  async function deploy() {
    const hostFac = await ethers.getContractFactory("Host");
    const StimulusFac = await ethers.getContractFactory("Stimulus");
    const mutantFac = await ethers.getContractFactory("Mutant");
    const labsFac = await ethers.getContractFactory("FusionLabsV2");
    const [owner, holder1, holder2] = await ethers.getSigners();

    const labsExpectedAddr = await getExpectedContractAddress(owner, 3);
    const host = await hostFac.deploy();
    await host.deployed();
    const stimulus = await StimulusFac.deploy();
    await stimulus.deployed();
    const mutant = await mutantFac.deploy(labsExpectedAddr);
    await mutant.deployed();
    const labs = await labsFac.deploy(
      host.address,
      stimulus.address,
      mutant.address,
      1000
    );
    await labs.deployed();

    // console.log({
    //   host: host.address,
    //   stimulus: stimulus.address,
    //   mutant: mutant.address,
    //   labsExpect: labsExpectedAddr,
    //   labs: labs.address,
    //   //   owner: owner.address,
    //   holder1: holder1.address,
    //   holder2: holder2.address,
    // });

    return {
      host,
      stimulus,
      mutant,
      labs,
      owner,
      holder1,
      holder2,
    };
  }

  it("Should be able to mint NFT", async () => {
    const { host, stimulus, holder1, mutant, labs, holder2 } = await deploy();
    // console.log({
    //   host: host.address,
    //   stimulus: stimulus.address,
    //   mutant: mutant.address,
    //   labs: labs.address,
    //   //   owner: owner.address,
    //   holder1: holder1.address,
    //   holder2: holder2.address,
    // });
    await host.connect(holder1).mint();
    await stimulus.connect(holder1).mint();
    expect((await host.balanceOf(holder1.address)).toString()).to.equal("1");
    expect((await stimulus.balanceOf(holder1.address)).toString()).to.equal(
      "1"
    );
  });

  it("should start minting at tokenId 1 and has correct totalSupply", async () => {
    const { holder1, host } = await deploy();

    await host.connect(holder1).mint();
    await host.connect(holder1).mint();

    const totalSupply = await host.totalSupply();
    const owner = await host.ownerOf("1");
    const owner2 = await host.ownerOf("2");

    expect(totalSupply.toString()).to.equal("2");
    expect(owner.toString() === holder1.address).to.be.true;
    expect(owner2.toString() === holder1.address).to.be.true;
  });

  it("should be able to mint mutant after host and stimulus locked in the labs DO IT IN ONE GO!", async () => {
    const { host, stimulus, labs, mutant, holder1 } = await deploy();

    await host.connect(holder1).mint();
    await stimulus.connect(holder1).mint();
    await host.connect(holder1).approve(labs.address, "1");
    await stimulus.connect(holder1).approve(labs.address, "1");
    //lock
    //fusion
    await labs.connect(holder1).fusion("1", "1");

    const totalSupply = await mutant.totalSupply();
    expect(totalSupply.toString()).to.equal("1");
  });
});
