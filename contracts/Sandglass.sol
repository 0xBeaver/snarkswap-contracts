// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {
    SafeMath
} from "@openzeppelin/contracts/contracts/utils/math/SafeMath.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {ISnarkswapFactory} from "./interfaces/ISnarkswapFactory.sol";
import {Constant as C} from "./libraries/Constant.sol";
import {ControlledByPair} from "./helper/ControlledByPair.sol";

contract Sandglass is ControlledByPair {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Staking {
        address darkener;
        uint256 darkenedAt;
        uint256 amount;
        address solver;
    }

    struct ImmutableConfig {
        address factory;
        address stakingToken;
        uint256 difficultyPrice;
        uint256 maxDifficulty;
        uint256 freeDifficulty;
        uint256 preferentialPeriod;
    }

    mapping(address => mapping(bytes32 => Staking)) public stakings;

    ImmutableConfig public config;

    constructor(
        address factory,
        address stakingToken,
        uint256 difficultyPrice,
        uint256 maxDifficulty,
        uint256 freeDifficulty,
        uint256 preferentialPeriod
    ) {
        config.factory = factory;
        config.stakingToken = stakingToken;
        config.difficultyPrice = difficultyPrice;
        config.maxDifficulty = maxDifficulty;
        config.freeDifficulty = freeDifficulty;
        config.preferentialPeriod = preferentialPeriod;
    }

    function stakeFrom(
        address darkener,
        uint8 difficulty,
        bytes32 darkness
    ) external onlySnarkswapPair(config.factory) {
        address pair = msg.sender;
        Staking storage staking = stakings[pair][darkness];
        require(staking.darkener == address(0), "already darkened");
        // Staking amount is proportional to the difficulty. Free difficulty is 20
        uint256 amount =
            config.difficultyPrice *
                (10**(config.maxDifficulty - difficulty + 18));
        // It doesn't need safe math. no overflow here.

        IERC20(config.stakingToken).safeTransferFrom(
            darkener,
            address(this),
            staking.amount
        );
        // Take fee if the darkening is too difficult.
        uint256 fee =
            difficulty > config.freeDifficulty
                ? amount.mul(difficulty - config.freeDifficulty).mul(3).div(100)
                : 0;
        IERC20(config.stakingToken).safeTransfer(
            ISnarkswapFactory(config.factory).feeTo(),
            fee
        );
        // Record the staking.
        staking.darkener = darkener;
        staking.darkenedAt = block.timestamp;
        staking.amount = amount.sub(fee);
    }

    function resolve(address solver, bytes32 darkness)
        public
        onlySnarkswapPair(config.factory)
    {
        address pair = msg.sender;
        Staking storage staking = stakings[pair][darkness];
        staking.solver = solver;
        if (staking.solver == staking.darkener) {
            unstake(pair, darkness);
        }
    }

    function unstake(address pair, bytes32 darkness) public {
        Staking storage staking = stakings[pair][darkness];
        require(staking.solver != address(0), "Still dark");
        if (block.timestamp - staking.darkenedAt < config.preferentialPeriod) {
            // The trader has 10 minutes advantage to withdraw the staking.
            require(
                msg.sender == staking.darkener,
                "Only the darkener can withdraw"
            );
        } else {
            require(
                msg.sender == staking.solver,
                "Only the solver can withdraw"
            );
        }
        IERC20(config.stakingToken).safeTransfer(msg.sender, staking.amount);
        delete stakings[pair][darkness];
    }
}
