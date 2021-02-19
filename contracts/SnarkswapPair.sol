// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import {
    UniswapV2Pair
} from "@0xBeaver/uniswap-v2-core/contracts/UniswapV2Pair.sol";
import {
    SafeMath
} from "@openzeppelin/contracts/contracts/utils/math/SafeMath.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {INotePool} from "./interfaces/INotePool.sol";
import {ISandglass} from "./interfaces/ISandglass.sol";
import {Verifier, VK, Proof} from "./libraries/Verifier.sol";
import {SwapVerifier} from "./verifiers/SwapVerifier.sol";
import {ISwapVerifier, SnarkSwap} from "./interfaces/ISwapVerifier.sol";
import {Constant as C} from "./libraries/Constant.sol";
import {Undarkener} from "./libraries/Undarkener.sol";

contract SnarkswapPair is UniswapV2Pair {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Verifier for VK;

    bytes32 public darkness;
    address public darkener;
    uint256 public darkenedAt;

    struct ImmutableConfig {
        address sandglass;
        address swapVerifier;
        address notePool;
    }

    ImmutableConfig public config;

    uint256 private constant MAX_DIFFICULTY = 30; // mestimated: 9 hours
    uint8 private constant FEE_NUMERATOR = 3; // mestimated: 9 hours
    uint16 private constant FEE_DENOMINATOR = 1000; // mestimated: 9 hours

    event Darkened(bytes32 darkness, uint224 mask);
    event Undarkened(bytes32 darkness, uint112 reserve0, uint112 reserve1);

    modifier notInTheDark() {
        require(darkness == bytes32(0), "too dark");
        _;
    }

    constructor() UniswapV2Pair() {
    }

    function initialize2(
        address sandglass,
        address swapVerifier,
        address notePool
    ) public {
        config.sandglass = sandglass;
        config.swapVerifier = swapVerifier;
        config.notePool = notePool;
    }

    /**
     * @notice snarkswap() darkens the pair.
     */
    function swapInTheDark(
        uint256 sourceA,
        uint256 sourceB,
        uint256 hRatio,
        uint112 hReserve0,
        uint112 hReserve1,
        uint224 mask,
        uint256 outputA,
        uint256 outputB,
        uint128 salt,
        Proof calldata proof
    ) public notInTheDark {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        // Given public inputs and private inputs satisfy the darkening protocol.
        // See circuits/darkening.circom for more details.
        // this consumes about 300k gas.
        require(
            ISwapVerifier(config.swapVerifier).verifySwap(
                SnarkSwap(
                    sourceA,
                    sourceB,
                    reserve0,
                    reserve1,
                    mask,
                    hRatio,
                    hReserve0,
                    hReserve1,
                    salt,
                    outputA,
                    outputB,
                    token0,
                    token1,
                    FEE_NUMERATOR,
                    FEE_DENOMINATOR
                ),
                proof
            ),
            "zk fails"
        );
        // It records the darkness and the swap ratio goes into the dark. Can't run in front in the dark!
        darkness = keccak256(
            abi.encodePacked(hRatio, hReserve0, hReserve1, mask)
        );
        // stake token (tx signer should approve first)
        {
            uint8 difficulty = calcDifficulty(mask);
            require(difficulty <= MAX_DIFFICULTY);
            ISandglass(config.sandglass).stakeFrom(
                msg.sender,
                difficulty,
                darkness
            );
            // Consumes sourceA & sourceB. But doesn't know the detail of outputA and outputB
            INotePool(config.notePool).update(
                sourceA,
                sourceB,
                outputA,
                outputB
            );
        }
        emit Darkened(darkness, mask);
    }

    /**
     * @notice The darkness hides the swap ratio. It can be resolved by
     *      solving the proof of work puzzle which is the poseidon hash of
     *      private input data of the dark swap.
     */
    function undarken(
        uint112 reserve0,
        uint112 reserve1,
        uint112 hReserve0,
        uint112 hReserve1,
        uint224 mask,
        uint128 salt
    ) public {
        bool solved =
            Undarkener.solve(
                darkness,
                reserve0,
                reserve1,
                hReserve0,
                hReserve1,
                mask,
                salt
            );
        require(solved, "failed to solve the darknesss");
        // resolve the sandglass.
        ISandglass(config.sandglass).resolve(msg.sender, darkness);
        // emit event
        emit Undarkened(darkness, reserve0, reserve1);
        // undarken
        delete darkness;
        // run pending swap
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        address inputToken = reserve0 > _reserve0 ? token0 : token1;
        uint256 amount0Out =
            inputToken == token0
                ? uint256(0)
                : uint256(_reserve0).sub(uint256(reserve0));
        uint256 amount1Out =
            inputToken == token1
                ? uint256(0)
                : uint256(_reserve1).sub(uint256(reserve1));
        require(amount0Out == 0 || amount1Out == 0, "one should be zero");
        uint256 amountInWithFee =
            inputToken == token0
                ? uint256(reserve0).sub(uint256(_reserve0))
                : uint256(reserve1).sub(uint256(_reserve1));
        uint256 amountIn = amountInWithFee.mul(1000).div(997);
        // Run the pending swap.
        IERC20(inputToken).safeTransferFrom(config.notePool, address(this), amountIn);
        this.swap(amount0Out, amount1Out, config.notePool, new bytes(0));
    }

    function mint(address to)
        public
        override
        notInTheDark
        returns (uint256 liquidity)
    {
        return super.mint(to);
    }

    function burn(address to)
        public
        override
        notInTheDark
        returns (uint256 amount0, uint256 amount1)
    {
        return super.burn(to);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) public override notInTheDark {
        super.swap(amount0Out, amount1Out, to, data);
    }

    function skim(address to) public override notInTheDark {
        super.skim(to);
    }

    function sync() public override notInTheDark {
        super.sync();
    }

    function darkened() public view returns (bool) {
        return darkness != bytes32(0);
    }

    function calcDifficulty(uint224 mask) public pure returns (uint8) {
        uint8 difficulty = 0;
        for (uint8 i = 0; i < 224; i++) {
            if (mask & (1 << i) != 0) difficulty += 1;
        }
        return difficulty;
    }
}
