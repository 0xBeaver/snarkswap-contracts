// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface INotePool {
    // only for SnarkswapPair.sol
    function transact(
        address spender,
        uint256 sourceA,
        uint256 sourceB,
        uint256 outputA,
        uint256 outputB,
        bytes calldata encrypted
    ) external;

    // only for SnarkswapFactory.sol
    function approvePair(
        address token0,
        address token1,
        address pair
    ) external;
}
