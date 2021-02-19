// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

library Constant {
    bytes32 constant MAX_DIFFICULTY = keccak256("MAX_DIFFICULTY"); // 30 => mestimated: 9 hours
    bytes32 constant SANDGLASS = keccak256("SANDGLASS");
    bytes32 constant FACTORY = keccak256("FACTORY");
    bytes32 constant DIFFICULTY_PRICE = keccak256("DIFFICULTY_PRICE");
    bytes32 constant STAKING_TOKEN = keccak256("STAKING_TOKEN");
    bytes32 constant FREE_DIFFICULTY = keccak256("FREE_DIFFICULTY");
    bytes32 constant POW_ADVANTAGE = keccak256("POW_ADVANTAGE");
    bytes32 constant PROTOCOL_FEE_TO = keccak256("PROTOCOL_FEE_TO");
    bytes32 constant FEE_NUMERATOR = keccak256("FEE_NUMERATOR");
    bytes32 constant FEE_DENOMINATOR = keccak256("FEE_DENOMINATOR");
    uint256 constant PRIME_Q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
}