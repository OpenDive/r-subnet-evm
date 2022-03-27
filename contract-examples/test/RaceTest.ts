import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";
let race;
let accounts: SignerWithAddress[];
describe("Race Precompile Test", function () {
  before(async function () {
    owner = await ethers.getSigner(adminAddress);
    const RACE: ContractFactory = await ethers.getContractFactory(
      "raceExample",
      { signer: owner }
    );
    race = await RACE.deploy();
    await race.deployed();
    const contractAddress: string = race.address;
    console.log(`Contract deployed to: ${contractAddress}`);

    accounts = await ethers.getSigners();
  });

  it("should add contract deployer as owner", async function () {
    let birds = [
      231022021158823917881,
      428010110896281635620,
      445110010421432826583,
      109120120079152380766,
      411030001858947528507,
      238100021829839758177,
      139112100209515801702,
      345130000303715409242,
      422141021330139117820,
      206112000598436853506,
    ];
    let track = [30, 40, 25, 50, 80];
    let results = await race.testRace(birds, track);
    console.log(results);
  });
});
