import { ethers, waffle } from "hardhat";
import chai, { expect } from "chai";
import { Contract, constants, BigNumber, Signer } from "ethers";
import { parseEther, randomBytes, hexlify } from "ethers/lib/utils";
import { utils, Note, getNoteHash, swap, pow } from "@snarkswap/client";

import { expandTo18Decimals } from "./shared/utilities";
import { pairFixture } from "./shared/fixtures";
import { SwapType } from "@snarkswap/client/build/main/lib/swap";

chai.use(waffle.solidity);

const { AddressZero } = constants;
const provider = ethers.provider;

describe("SnarkswapPair", () => {
  let wallet: Signer, other: Signer;
  let walletAddress: string;
  let token0: Contract;
  let token1: Contract;
  let stakingToken: Contract;
  let sandglass: Contract;
  let pair: Contract;
  let notePool: Contract;
  let privKey: BigNumber;
  let pubKey: readonly BigNumber[];
  beforeEach(async () => {
    [wallet, other] = await ethers.getSigners();
    walletAddress = await wallet.getAddress();
    const fixture = await pairFixture(wallet);
    notePool = fixture.notePool;
    token0 = fixture.token0;
    token1 = fixture.token1;
    pair = fixture.pair;
    sandglass = fixture.sandglass;
    stakingToken = fixture.stakingToken;
    privKey = await utils.genEdDSAPrivKey(pair.address, wallet);
    pubKey = utils.privToPubKey(privKey);
    await token0.approve(notePool.address, constants.MaxUint256);
    await token1.approve(notePool.address, constants.MaxUint256);
    await stakingToken.approve(sandglass.address, constants.MaxUint256);
  });

  async function addLiquidity(
    token0Amount: BigNumber,
    token1Amount: BigNumber
  ) {
    await token0.transfer(pair.address, token0Amount);
    await token1.transfer(pair.address, token1Amount);
    await pair.mint(walletAddress);
  }

  const swapTestCases: BigNumber[][] = [
    [1, 5, 10, "1662497915624478906"],
    [1, 10, 5, "453305446940074565"],

    [2, 5, 10, "2851015155847869602"],
    [2, 10, 5, "831248957812239453"],

    [1, 10, 10, "906610893880149131"],
    [1, 100, 100, "987158034397061298"],
    [1, 1000, 1000, "996006981039903216"],
  ].map((a) =>
    a.map((n) =>
      typeof n === "string" ? BigNumber.from(n) : expandTo18Decimals(n)
    )
  );
  describe("hide swap", () => {
    swapTestCases.forEach((swapTestCase, i) => {
      it(`getInputPrice:${i}`, async () => {
        const [
          swapAmount,
          token0Amount,
          token1Amount,
          expectedOutputAmount,
        ] = swapTestCase;
        const note0: Note = {
          address: token0.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        const note1: Note = {
          address: token1.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        await addLiquidity(token0Amount, token1Amount);
        const [reserve0, reserve1] = await pair.getReserves();
        const snarkswap = await swap.hideSwap(
          privKey,
          reserve0,
          reserve1,
          note0,
          note1,
          token0.address,
          token1.address,
          swapAmount,
          SwapType.Token0In,
          { numerator: 3, denominator: 1000 },
          10
        );
        const amountIn = [snarkswap.outputA, snarkswap.outputB]
          .filter((note) => BigNumber.from(token0.address).eq(note.address))
          .reduce((acc, note) => acc.add(note.amount), BigNumber.from(0))
          .sub(note0.amount)
          .mul(-1);
        const amountOut = [snarkswap.outputA, snarkswap.outputB]
          .filter((note) => BigNumber.from(token1.address).eq(note.address))
          .reduce((acc, note) => acc.add(note.amount), BigNumber.from(0))
          .sub(note1.amount);
        expect(swapAmount).eq(amountIn);
        expect(expectedOutputAmount).eq(amountOut);
      });
    });
  });
  describe("swapInTheDark()", () => {
    swapTestCases.forEach((swapTestCase, i) => {
      it(`swapInTheDark:${i}`, async () => {
        const [
          swapAmount,
          token0Amount,
          token1Amount,
          expectedOutputAmount,
        ] = swapTestCase;
        const note0: Note = {
          address: token0.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        const note1: Note = {
          address: token1.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        await addLiquidity(token0Amount, token1Amount);
        await notePool.deposit(
          note0.address,
          note0.amount,
          note0.pubKey,
          note0.salt
        );
        await notePool.deposit(
          note1.address,
          note1.amount,
          note1.pubKey,
          note1.salt
        );
        const [reserve0, reserve1] = await pair.getReserves();
        const snarkswap = await swap.hideSwap(
          privKey,
          reserve0,
          reserve1,
          note0,
          note1,
          token0.address,
          token1.address,
          swapAmount,
          SwapType.Token0In,
          { numerator: 3, denominator: 1000 },
          10
        );
        await expect(
          pair.swapInTheDark(
            getNoteHash(note0),
            getNoteHash(note1),
            snarkswap.hRatio,
            snarkswap.hReserve0,
            snarkswap.hReserve1,
            snarkswap.mask,
            getNoteHash(snarkswap.outputA),
            getNoteHash(snarkswap.outputB),
            snarkswap.salt,
            snarkswap.encryptedOutputs,
            snarkswap.proof
          )
        )
          .to.emit(pair, "Darkened")
          .withArgs(
            snarkswap.darkness,
            snarkswap.mask,
            hexlify(snarkswap.encryptedOutputs)
          );
      });
    });
  });
  describe("undarken()", () => {
    swapTestCases.forEach((swapTestCase, i) => {
      it(`undarken:${i}`, async () => {
        const [
          swapAmount,
          token0Amount,
          token1Amount,
          expectedOutputAmount,
        ] = swapTestCase;
        const note0: Note = {
          address: token0.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        const note1: Note = {
          address: token1.address,
          amount: parseEther("3"),
          pubKey,
          salt: BigNumber.from(randomBytes(16)),
        };
        await addLiquidity(token0Amount, token1Amount);
        await notePool.deposit(
          note0.address,
          note0.amount,
          note0.pubKey,
          note0.salt
        );
        await notePool.deposit(
          note1.address,
          note1.amount,
          note1.pubKey,
          note1.salt
        );
        const [reserve0, reserve1] = await pair.getReserves();
        const snarkswap = await swap.hideSwap(
          privKey,
          reserve0,
          reserve1,
          note0,
          note1,
          token0.address,
          token1.address,
          swapAmount,
          SwapType.Token0In,
          { numerator: 3, denominator: 1000 },
          10
        );
        const {
          darkness,
          hRatio,
          hReserve0,
          hReserve1,
          mask,
          salt,
        } = snarkswap;
        await pair
          .connect(wallet)
          .swapInTheDark(
            getNoteHash(note0),
            getNoteHash(note1),
            hRatio,
            hReserve0,
            hReserve1,
            mask,
            getNoteHash(snarkswap.outputA),
            getNoteHash(snarkswap.outputB),
            salt,
            snarkswap.encryptedOutputs,
            snarkswap.proof
          );
        const hunt = await pow.solve(
          darkness,
          hReserve0,
          hReserve1,
          mask,
          salt
        );
        await expect(
          pair
            .connect(wallet)
            .undarken(
              hunt.reserve0,
              hunt.reserve1,
              hReserve0,
              hReserve1,
              mask,
              salt
            )
        )
          .to.emit(pair, "Undarkened")
          .withArgs(darkness, hunt.reserve0, hunt.reserve1);
      });
    });
  });
});
