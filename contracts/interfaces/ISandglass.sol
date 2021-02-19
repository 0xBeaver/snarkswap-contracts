// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

interface ISandglass {
    function stakeFrom(
        address darkener,
        uint8 difficulty,
        bytes32 darkness
    ) external;

    function resolve(address solver, bytes32 darkness) external;
    function unstake(address pair, bytes32 darkness) external;
}