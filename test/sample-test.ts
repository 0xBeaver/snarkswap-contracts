import { ethers } from "hardhat";
import { expect } from "chai";
import { deployContractSet } from "../scripts/deploy-set";

const setTimestamp = async (timestamp: number) =>
  await ethers.provider.send("evm_setNextBlockTimestamp", [timestamp]);

describe("Commitment Dao", function () {
  let contracts;
  before(async () => {
    const signers = await ethers.getSigners();
    contracts = await deployContractSet(
      signers.map((signer) => signer.address)
    );
  });
  it("Should return the deployed contracts", async function () {
    expect(contracts.visionToken.address).to.be.a("string");
  });
});
