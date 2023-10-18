// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {NewIdea} from "../src/NewIdea.sol";
import {HookTest} from "./utils/Hook.t.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {HookMiner} from "./utils/libraries/HookMiner.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {NewIdeaImplementation} from "../src/implementation/NewIdeaImplementation.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

contract NewIdeaTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    NewIdea public hook;
    PoolKey poolKey;
    PoolId poolId;

    address alice = makeAddr("alice");

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

        NewIdeaImplementation impl = new NewIdeaImplementation(manager, hook);
        HookTest.etchHook(address(impl), address(hook));

        /// @dev Create pool
        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        poolId = poolKey.toId();
        manager.initialize(poolKey, SQRT_RATIO_1_1, abi.encode(""));

        // Provide liquidity to the pool
        vm.startPrank(msg.sender);
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(-60, 60, 1_000e18),
            ZERO_BYTES
        );
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(-120, 120, 1_000e18),
            ZERO_BYTES
        );
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(
                TickMath.minUsableTick(60),
                TickMath.maxUsableTick(60),
                1_000e18
            ),
            ZERO_BYTES
        );
        vm.stopPrank();
    }

    // Add your tests here:
    function test_balances() public {
        // DAI amount
        assertEq(token0.balanceOf(msg.sender), 1_000_000e18);
        // New token amount
        assertEq(token1.balanceOf(msg.sender), 1_000_000e18);
    }
}
