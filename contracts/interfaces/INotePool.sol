// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

interface INotePool {
    // only for SnarkswapPair.sol
    function update(uint256 sourceX, uint256 sourceY, uint256 outputX, uint256 outputY) external;
}