import chai, { expect } from "chai";
import { waffle } from "hardhat";
import { Contract, Signer, BigNumber, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { gadgetFixture } from "./shared/fixtures";
import {
  keccak256,
  parseEther,
  randomBytes,
  defaultAbiCoder,
} from "ethers/lib/utils";
import { utils, Note, getNoteHash } from "@snarkswap/client";
import { parse } from "path";

chai.use(solidity);

describe("NoteHash", async () => {
  let wallet: Signer;
  let noteHash: Contract;
  let privKey: BigNumber;
  let pubKey: readonly BigNumber[];
  beforeEach(async () => {
    [wallet] = await waffle.provider.getWallets();
    const fixture = await gadgetFixture(wallet);
    noteHash = fixture.noteHash;
    privKey = await utils.genEdDSAPrivKey("helloworld", wallet);
    pubKey = utils.privToPubKey(privKey);
  });

  it("poseidon T6 (for 5 inputs)", async () => {
    const amount = parseEther("1");
    const salt = BigNumber.from(randomBytes(16));
    const note: Note = {
      address: BigNumber.from(await wallet.getAddress()),
      amount,
      pubKey,
      salt,
    };
    const _hash = await noteHash.callStatic.poseidon([
      note.address,
      note.amount,
      note.pubKey[0],
      note.pubKey[1],
      note.salt,
    ]);
    expect(_hash).satisfies((h) => h.eq(getNoteHash(note)));
  });
});
