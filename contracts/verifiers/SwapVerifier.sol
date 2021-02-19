// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import {VK, Verifier, Proof} from "../libraries/Verifier.sol";
import {SnarkSwap} from "../interfaces/ISwapVerifier.sol";

contract SwapVerifier {
    using Verifier for VK;

    VK public key;

    constructor() {
        // initialize vk here
    }

    function verifySwap(
        SnarkSwap memory swap,
        Proof memory proof
    ) public view returns (bool result) {
        uint256[] memory input = new uint256[](15);
        input[0] = swap.sourceA;
        input[1] = swap.sourceB;
        input[2] = uint256(swap.reserve0);
        input[3] = uint256(swap.reserve1);
        input[4] = uint256(swap.mask);
        input[5] = swap.hRatio;
        input[6] = uint256(swap.hReserve0);
        input[7] = uint256(swap.hReserve1);
        input[8] = uint256(swap.ratioSalt);
        input[9] = swap.outputA;
        input[10] = swap.outputB;
        input[11] = uint256(uint160(swap.address0));
        input[12] = uint256(uint160(swap.address0));
        input[13] = uint256(swap.feeNumerator);
        input[13] = uint256(swap.feeDenominator);
        /**
         * private inputs
         * pInput[0]: ~~
         * pInput[1]: ~~
         * pInput[2]: ~~
         */
        return key.verify(input, proof);
    }
}
