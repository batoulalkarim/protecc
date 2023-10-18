// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {NewIdea} from "../src/NewIdea.sol";
import {HookTest} from "./utils/Hook.t.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {HookMiner} from "./utils/libraries/HookMiner.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

contract NewIdeaTest is HookTest, Deployers, GasSnapshot {
    NewIdea public hook;

    function setUp() public {
        HookTest.initHookTestEnv();

        /// @dev Will probably need to revist initialize, modify position, and donate
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(NewIdea).creationCode,
            abi.encode(address(manager))
        );

        hook = new NewIdea{salt: salt}(manager);

        require(
            address(hook) == hookAddress,
            "NewHookTest:Hook address mismatch"
        );
    }
}
