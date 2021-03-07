import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import poseidonGenContract from "circomlib/src/poseidon_gencontract";

const poseidonGenContract = require("circomlib/src/poseidon_gencontract");

import { expandTo18Decimals } from "./utilities";

import HRatioHashJson from "../../artifacts/contracts/hash/HRatioHash.sol/HRatioHash.json";
import NoteHashJson from "../../artifacts/contracts/hash/NoteHash.sol/NoteHash.json";

interface GadgetFixture {
  hRatioHash: Contract;
  noteHash: Contract;
  undarkener: Contract;
  swapVerifier: Contract;
  eddsaVerifier: Contract;
  stakingToken: Contract;
}

interface FactoryFixture extends GadgetFixture {
  factory: Contract;
  sandglass: Contract;
  notePool: Contract;
}

interface PairFixture extends FactoryFixture {
  token0: Contract;
  token1: Contract;
  pair: Contract;
}

export async function gadgetFixture(signer: Signer): Promise<GadgetFixture> {
  const ERC20Tester = await ethers.getContractFactory("ERC20Tester");
  const HRatioHash = await ethers.getContractFactory(
    HRatioHashJson.abi,
    poseidonGenContract.createCode(3)
  );
  const NoteHash = await ethers.getContractFactory(
    NoteHashJson.abi,
    poseidonGenContract.createCode(5)
  );
  const hRatioHash = await HRatioHash.deploy();
  const noteHash = await NoteHash.deploy();
  const Undarkener = (
    await ethers.getContractFactory("Undarkener", {
      libraries: {
        HRatioHash: hRatioHash.address,
      },
    })
  ).connect(signer);
  const SwapVerifier = await ethers.getContractFactory("SwapVerifier");
  const EdDSAVerifier = await ethers.getContractFactory("EdDSAVerifier");
  const stakingToken = await (
    await ERC20Tester.deploy(expandTo18Decimals(10000))
  ).connect(signer);
  const undarkener = await Undarkener.deploy();
  const swapVerifier = await SwapVerifier.deploy();
  const eddsaVerifier = await EdDSAVerifier.deploy();
  return {
    noteHash,
    hRatioHash,
    undarkener,
    swapVerifier,
    eddsaVerifier,
    stakingToken,
  };
}

export async function factoryFixture(signer: Signer): Promise<FactoryFixture> {
  const fixture = await gadgetFixture(signer);
  const SnarkswapFactory = (
    await ethers.getContractFactory("SnarkswapFactory")
  ).connect(signer);
  const NotePool = (
    await ethers.getContractFactory("NotePool", {
      libraries: {
        NoteHash: fixture.noteHash.address,
      },
    })
  ).connect(signer);
  const Sandglass = (await ethers.getContractFactory("Sandglass")).connect(
    signer
  );
  const sandglass = await Sandglass.deploy();
  const notePool = await NotePool.deploy();
  const factory = await SnarkswapFactory.deploy(
    sandglass.address,
    fixture.undarkener.address,
    fixture.swapVerifier.address,
    notePool.address,
    await signer.getAddress()
  );
  await notePool.initialize(factory.address, fixture.eddsaVerifier.address);
  await sandglass.initialize(
    factory.address,
    fixture.stakingToken.address,
    10,
    30,
    20,
    600
  );
  return { factory, sandglass, notePool, ...fixture };
}

export async function pairFixture(signer: Signer): Promise<PairFixture> {
  const ERC20Tester = await ethers.getContractFactory("ERC20Tester");
  const fixture = await factoryFixture(signer);
  const tokenA = await ERC20Tester.deploy(expandTo18Decimals(10000));
  const tokenB = await ERC20Tester.deploy(expandTo18Decimals(10000));
  await fixture.factory.createPair(tokenA.address, tokenB.address);
  const pairAddress = await fixture.factory.getPair(
    tokenA.address,
    tokenB.address
  );
  const pair = await ethers.getContractAt("SnarkswapPair", pairAddress, signer);
  const token0Address = await pair.token0();
  const token0 = tokenA.address === token0Address ? tokenA : tokenB;
  const token1 = tokenA.address === token0Address ? tokenB : tokenA;

  return { token0, token1, pair, ...fixture };
}
