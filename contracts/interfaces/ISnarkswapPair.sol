// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {
    IUniswapV2Pair
} from "@0xBeaver/uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol";

struct PairConfig {
    address sandglass;
    address undarkener;
    address swapVerifier;
    address notePool;
}

interface ISnarkswapPair is IUniswapV2Pair {
    function initialize2(PairConfig memory config) external;
}
