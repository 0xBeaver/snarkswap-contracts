// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {ISnarkswapFactory} from '../interfaces/ISnarkswapFactory.sol';
import {ISnarkswapPair} from '../interfaces/ISnarkswapPair.sol';

contract ControlledByPair {
    modifier onlySnarkswapPair(address factory) {
        address token0 = ISnarkswapPair(msg.sender).token0();
        address token1 = ISnarkswapPair(msg.sender).token1();
        require(
            ISnarkswapFactory(factory).getPair(token0, token1) == msg.sender,
            "not a registered pair"
        );
        _;
    }
}
