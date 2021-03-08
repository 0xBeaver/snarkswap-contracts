// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import {
    SafeERC20
} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {Proof} from "./libraries/Verifier.sol";
import {NoteHash} from "./hash/NoteHash.sol";
import {IEdDSAVerifier} from "./interfaces/IEdDSAVerifier.sol";
import {ControlledByPair} from "./helper/ControlledByPair.sol";

contract NotePool is ControlledByPair {
    using SafeERC20 for IERC20;

    uint256 constant PRIME_Q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    mapping(uint256 => bool) notes;

    struct ImmutableConfig {
        address factory;
        address eddsaVerifier;
    }

    ImmutableConfig public config;

    event Deposit(
        address indexed depositor,
        uint256 noteHash,
        address token,
        uint256 amount,
        bytes32 eddsaId,
        uint128 salt
    );
    event Withdraw(
        address indexed depositor,
        uint256 noteHash,
        address token,
        uint256 amount,
        bytes32 eddsaId,
        uint128 salt
    );

    constructor() {}

    function initialize(address factory, address eddsaVerifier) public {
        require(
            config.factory == address(0) && config.eddsaVerifier == address(0),
            "already initialized"
        );
        config.factory = factory;
        config.eddsaVerifier = eddsaVerifier;
    }

    function approvePair(
        address token0,
        address token1,
        address pair
    ) public {
        require(
            msg.sender == config.factory,
            "only factory created pool allowed"
        );
        IERC20(token0).approve(pair, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        IERC20(token1).approve(pair, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function update(
        uint256 sourceX,
        uint256 sourceY,
        uint256 outputX,
        uint256 outputY
    ) public onlySnarkswapPair(config.factory) {
        require(notes[sourceX] && notes[sourceY], "note does not exist");
        delete notes[sourceX];
        delete notes[sourceY];
        require(!notes[outputX] && !notes[outputY], "output already exists");
        notes[outputX] = true;
        notes[outputY] = true;
    }

    function deposit(
        address token,
        uint256 amount,
        uint256[2] memory edDSAPubKey,
        uint128 salt
    ) public {
        uint256 noteHash =
            NoteHash.poseidon(
                [
                    uint256(uint160(token)),
                    amount,
                    edDSAPubKey[0],
                    edDSAPubKey[1],
                    uint256(salt)
                ]
            );
        require(!notes[noteHash], "output already exists");
        notes[noteHash] = true;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        bytes32 eddsaId =
            keccak256(abi.encodePacked(edDSAPubKey[0], edDSAPubKey[1]));
        emit Deposit(msg.sender, noteHash, token, amount, eddsaId, salt);
    }

    // EdDSA sig for withdrawal uses keccak256 for its hash function while
    // it uses Pedersen in SNARK circuit.
    function withdraw(
        address token,
        uint256 amount,
        uint256[2] memory edDSAPubKey,
        uint128 salt,
        address to,
        Proof memory proof
    ) public {
        uint256 noteHash =
            NoteHash.poseidon(
                [
                    uint256(uint160(token)),
                    amount,
                    edDSAPubKey[0],
                    edDSAPubKey[1],
                    uint256(salt)
                ]
            );
        require(notes[noteHash], "Note doesn't exist");
        delete notes[noteHash];
        uint256 message =
            uint256(keccak256(abi.encodePacked(noteHash, to))) % PRIME_Q;
        require(
            IEdDSAVerifier(config.eddsaVerifier).verifyEdDSA(
                message,
                edDSAPubKey,
                proof
            ),
            "Invalid EdDSA signature"
        );
        IERC20(token).safeTransfer(to, amount);
        bytes32 eddsaId =
            keccak256(abi.encodePacked(edDSAPubKey[0], edDSAPubKey[1]));
        emit Withdraw(msg.sender, noteHash, token, amount, eddsaId, salt);
    }
}
