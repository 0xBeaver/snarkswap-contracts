import chai, { expect } from "chai";
import { waffle } from "hardhat";
import { Contract, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
import * as snarkswap from "@snarkswap/client";

import { gadgetFixture } from "./shared/fixtures";

chai.use(solidity);

describe("EdDSAVerifier", async () => {
  let wallet: Signer, other: Signer;
  let eddsaVerifier: Contract;
  beforeEach(async () => {
    [wallet, other] = await waffle.provider.getWallets();
    const fixture = await gadgetFixture(wallet);
    eddsaVerifier = fixture.eddsaVerifier;
  });

  it("verifier", async () => {
    const msg = '1234';
    const privKey = '12341234';
    const pubKey = snarkswap.utils.privToPubKey(privKey);
    const proof = await snarkswap.eddsa.signEdDSA(msg, privKey);
    expect(
      await eddsaVerifier.callStatic.verifyEdDSA(msg, pubKey, proof)
    ).to.eq(true);
  });
});
