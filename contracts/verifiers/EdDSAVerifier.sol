// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;
import {VK, Verifier, Proof} from "../libraries/Verifier.sol";

contract EdDSAVerifier {
    using Verifier for VK;

    VK public key;

    constructor() {
        // initialize vk here
    }

    function verifyEdDSA(
        uint256 message,
        uint256[2] memory pubkey,
        Proof memory proof
    ) public view returns (bool result) {
        uint256[] memory input = new uint256[](6);
        input[0] = message;
        input[1] = pubkey[0];
        input[2] = pubkey[1];
        return key.verify(input, proof);
    }
}
