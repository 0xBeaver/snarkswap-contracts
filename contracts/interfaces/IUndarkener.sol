// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IUndarkener {
    function solve(
        bytes32 commitment, // exposed, stored
        uint112 reserve0, //hidden - found value
        uint112 reserve1, // hidden - found value
        uint112 hReserve0, // exposed
        uint112 hReserve1, // exposed
        uint224 mask, // exposed
        uint128 salt // exposed
    ) external pure returns (bool success);
}
