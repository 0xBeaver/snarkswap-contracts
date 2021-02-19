// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {HRatioHash} from "../hash/HRatioHash.sol";

library Undarkener {
    function solve(
        bytes32 commitment, // exposed, stored
        uint112 reserve0, //hidden - found value
        uint112 reserve1, // hidden - found value
        uint112 hReserve0, // exposed
        uint112 hReserve1, // exposed
        uint224 mask, // exposed
        uint128 salt // exposed
    ) external pure returns (bool success) {
        uint112 manipulatedBitFieldsA = hReserve0 ^ reserve0;
        uint112 manipulatedBitFieldsB = hReserve1 ^ reserve1;
        // https://ethresear.ch/t/performance-of-rescue-and-poseidon-hash-functions/7161
        // difficulty mask should have less than 25 non-zero bits => max 84 minutes to find the value

        uint224 manipulatedBitFields =
            (uint224(manipulatedBitFieldsA) << 112) +
                uint224(manipulatedBitFieldsB);

        if ((mask | manipulatedBitFields) != mask) {
            // (O)                           (X)
            // masked bits:      11100011 | masked bits:      10100111
            // manipulated bits: 11000011 | manipulated bits: 11100111
            return false;
        }
        uint256[3] memory inputs;
        inputs[0] = uint256(reserve0);
        inputs[1] = uint256(reserve1);
        inputs[2] = salt;
        uint256 hRatio = HRatioHash.poseidon(inputs);
        return
            commitment ==
            keccak256(abi.encodePacked(hRatio, hReserve0, hReserve1, mask));
    }
}
