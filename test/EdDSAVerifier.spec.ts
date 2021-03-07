import chai, { expect } from "chai";
import { waffle } from "hardhat";
import { Contract, Wallet } from "ethers";
import { solidity } from "ethereum-waffle";

import { gadgetFixture } from "./shared/fixtures";

chai.use(solidity);

const SAMPLE_EdDSA = {
  msg: "1234",
  pubKey: [
    "17003462792296272269832295169934420285613218706681299292070955540813010146373",
    "13042777426425787201005963860699505404919894351391857364446976781967611916943",
  ],
  proof: {
    a: [
      "18530334278102049218542050493920303882299288641684973212366571586284511700846",
      "13274022159409906956800491460654758775191839897285627462507440675748365502961",
    ],
    b: [
      [
        "18657960023184922677200514724137075480223644493403095499194212978142538076400",
        "4551503004326030020915155445933561173813373818340107607151568300655712026463",
      ].reverse(),
      [
        "2211277184858604224591676414574701572762300315027812927662294432690480028327",
        "13421526049468728816769267847909030696831099743850115028161077936433788891550",
      ].reverse(),
    ],
    c: [
      "20287560719627463173798515312461376150700708165410345232339170468543324791542",
      "6968292684752187948918286318663839148853415478555433307046664260693411209343",
    ],
  },
};

describe("EdDSAVerifier", async () => {
  let wallet: Wallet, other: Wallet;
  let eddsaVerifier: Contract;
  beforeEach(async () => {
    [wallet, other] = await waffle.provider.getWallets();
    const fixture = await gadgetFixture(wallet);
    eddsaVerifier = fixture.eddsaVerifier;
  });

  it("verifier", async () => {
    expect(
      await eddsaVerifier.callStatic.verifyEdDSA(
        SAMPLE_EdDSA.msg,
        SAMPLE_EdDSA.pubKey,
        SAMPLE_EdDSA.proof
      )
    ).to.eq(true);
  });
});
