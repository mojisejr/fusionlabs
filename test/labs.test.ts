import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { getExpectedContractAddress } from "../utils/getExpectedContractAddress";

describe("Labs Tests", async () => {
  async function deploy() {
    const hostFac = await ethers.getContractFactory("Host");
    const StimulusFac = await ethers.getContractFactory("Stimulus");
    const mutantFac = await ethers.getContractFactory("Mutant");
    const labsFac = await ethers.getContractFactory("FusionLabs");
    const [owner, holder1, holder2] = await ethers.getSigners();

    const host = await hostFac.deploy();
    await host.deployed();
    const stimulus = await StimulusFac.deploy();
    await stimulus.deployed();
    const labsExpectedAddr = getExpectedContractAddress(owner, 4);
    const mutant = await mutantFac.deploy(labsExpectedAddr);
    await mutant.deployed();
    const labs = labsFac.deploy(
      host.address,
      stimulus.address,
      mutant.address,
      1000
    );
    await (await labs).deployed();

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

  //   before(() => {});
  it("Deployment", async () => {
    const { labs } = await deploy();

    await expect((await labs).isFusionable("1", "1")).to.be.revertedWith(
      "not locked yet"
    );
  });

  it("Should be able to mint NFT", async () => {
    const { host, stimulus, holder1, mutant, labs, holder2 } = await deploy();
    console.log({
      host: host.address,
      stimulus: stimulus.address,
      mutant: mutant.address,
      labs: (await labs).address,
      //   owner: owner.address,
      holder1: holder1.address,
      holder2: holder2.address,
    });
    await host.connect(holder1).mint();
    await stimulus.connect(holder1).mint();
    expect((await host.balanceOf(holder1.address)).toString()).to.equal("1");
    expect((await stimulus.balanceOf(holder1.address)).toString()).to.equal(
      "1"
    );
  });

  it("should be able to locked token to the labs", async () => {
    //1 mint host
    //2 mint stimulus
    //3 locked
    //4 check
    const { host, stimulus, labs, holder1 } = await deploy();
    await host.connect(holder1).mint();
    await stimulus.connect(holder1).mint();
    await host.connect(holder1).approve((await labs).address, "0");
    await stimulus.connect(holder1).approve((await labs).address, "0");
    (await labs).connect(holder1).lock("0", "0");
    const balance = await host.balanceOf((await labs).address);
    console.log(balance);
    expect(await (await labs).isHostLocked("0")).to.equal(true);
    expect(await (await labs).isStimulusLocked("0")).to.equal(true);
  });
});
