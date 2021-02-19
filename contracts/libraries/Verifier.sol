// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import {Pairing} from "./Pairing.sol";

struct VK {
    Pairing.G1Point alpha1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] ic;
}

struct Proof {
    Pairing.G1Point a;
    Pairing.G2Point b;
    Pairing.G1Point c;
}

library Verifier {
    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    function verify(
        VK memory vk,
        uint256[] memory input,
        Proof memory proof
    ) internal view returns (bool) {
        require(input.length + 1 == vk.ic.length, "verifier-bad-input");
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.a.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.a.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.b.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.b.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.b.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.b.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.c.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.c.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < SNARK_SCALAR_FIELD,
                "verifier-gte-snark-scalar-field"
            );
            vkX = Pairing.plus(vkX, Pairing.scalar_mul(vk.ic[i + 1], input[i]));
        }
        vkX = Pairing.plus(vkX, vk.ic[0]);
        return
            Pairing.pairing(
                Pairing.negate(proof.a),
                proof.b,
                vk.alpha1,
                vk.beta2,
                vkX,
                vk.gamma2,
                proof.c,
                vk.delta2
            );
    }
}
