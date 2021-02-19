// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

import {Proof} from "../libraries/Verifier.sol";

interface IEdDSAVerifier {
    // only for SnarkswapPair.sol
    function verifyEdDSA(
        uint256 message,
        uint256[2] memory pubkey,
        Proof memory proof
    ) external view returns (bool);
}
