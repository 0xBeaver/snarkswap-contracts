// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {Proof} from "../libraries/Verifier.sol";

struct SnarkSwap {
    uint256 sourceA;
    uint256 sourceB;
    uint112 reserve0;
    uint112 reserve1;
    uint224 mask;
    uint256 hRatio;
    uint112 hReserve0;
    uint112 hReserve1;
    uint128 ratioSalt;
    uint256 outputA;
    uint256 outputB;
    address address0;
    address address1;
    uint8 feeNumerator;
    uint16 feeDenominator;
}

interface ISwapVerifier {
    function verifySwap(SnarkSwap memory swap, Proof memory proof)
        external
        view
        returns (bool result);
}
