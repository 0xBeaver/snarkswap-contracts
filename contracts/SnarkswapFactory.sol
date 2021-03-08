// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {
    UniswapV2Factory
} from "@0xBeaver/uniswap-v2-core/contracts/UniswapV2Factory.sol";
import {ISnarkswapPair} from "./interfaces/ISnarkswapPair.sol";
import {INotePool} from "./interfaces/INotePool.sol";
import {SnarkswapPair} from "./SnarkswapPair.sol";
import {PairConfig} from "./interfaces/ISnarkswapPair.sol";

contract SnarkswapFactory is UniswapV2Factory {
    PairConfig public pairConfig;

    constructor(
        address sandglass,
        address undarkener,
        address swapVerifier,
        address notePool,
        address feeTo
    ) UniswapV2Factory(feeTo) {
        pairConfig.sandglass = sandglass;
        pairConfig.undarkener = undarkener;
        pairConfig.swapVerifier = swapVerifier;
        pairConfig.notePool = notePool;
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns (address pair)
    {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) =
            tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "UniswapV2: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(SnarkswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISnarkswapPair(pair).initialize(token0, token1);
        ISnarkswapPair(pair).initialize2(pairConfig);
        INotePool(pairConfig.notePool).approvePair(token0, token1, pair);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
