import chai, { expect } from "chai";
import { waffle } from "hardhat";
import { Contract, Signer, BigNumber, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { pairFixture } from "./shared/fixtures";
import {
  keccak256,
  parseEther,
  randomBytes,
  defaultAbiCoder,
} from "ethers/lib/utils";
import { utils, Note, getNoteHash, eddsa } from "@snarkswap/client";

chai.use(solidity);

describe("NotePool", async () => {
  let wallet: Signer, other: Signer;
  let walletAddress: string;
  let notePool: Contract;
  let token0: Contract;
  let pair: Contract;
  let privKey: BigNumber;
  let pubKey: readonly BigNumber[];
  beforeEach(async () => {
    [wallet, other] = await waffle.provider.getWallets();
    walletAddress = await wallet.getAddress();
    const fixture = await pairFixture(wallet);
    notePool = fixture.notePool;
    token0 = fixture.token0;
    pair = fixture.pair;
    privKey = await utils.genEdDSAPrivKey(pair.address, wallet);
    pubKey = utils.privToPubKey(privKey);
    await token0.approve(notePool.address, constants.MaxUint256);
  });

  it("deposit", async () => {
    const amount = parseEther("1");
    const salt = BigNumber.from(randomBytes(16));
    const note: Note = {
      address: token0.address,
      amount,
      pubKey,
      salt,
    };
    const noteHash = getNoteHash(note);
    const pubkeyHash = keccak256(
      defaultAbiCoder.encode(["uint256", "uint256"], [pubKey[0], pubKey[1]])
    );
    await expect(
      notePool.deposit(token0.address, parseEther("1"), pubKey, salt)
    )
      .to.emit(notePool, "Deposit")
      .withArgs(
        walletAddress,
        noteHash,
        token0.address,
        amount,
        pubkeyHash,
        salt
      );
  });

  it("withdraw", async () => {
    const amount = parseEther("1");
    const salt = BigNumber.from(randomBytes(16));
    const note: Note = {
      address: token0.address,
      amount,
      pubKey,
      salt,
    };
    const noteHash = getNoteHash(note);
    await notePool.deposit(token0.address, parseEther("1"), pubKey, salt);
    const withdrawSnark = await eddsa.signWithdrawal(
      noteHash,
      walletAddress,
      privKey
    );
    const pubkeyHash = keccak256(
      defaultAbiCoder.encode(["uint256", "uint256"], [pubKey[0], pubKey[1]])
    );
    await expect(
      notePool.withdraw(
        token0.address,
        amount,
        pubKey,
        salt,
        walletAddress,
        withdrawSnark
      )
    )
      .to.emit(notePool, "Withdraw")
      .withArgs(
        walletAddress,
        noteHash,
        token0.address,
        amount,
        pubkeyHash,
        salt
      );
  });
});
