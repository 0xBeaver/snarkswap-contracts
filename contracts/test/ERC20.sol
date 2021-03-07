// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {ERC20} from "@openzeppelin/contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Tester is ERC20 {
    constructor(uint256 _totalSupply) ERC20("TEST", "_TESTSYMBOL") {
        _mint(msg.sender, _totalSupply);
    }
}
