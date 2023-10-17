// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseHook} from "periphery-next/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

contract NewHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: false,
                afterModifyPosition: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function beforeSwap(
        address sender,
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external view override returns (bytes4) {
        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        return BaseHook.afterSwap.selector;
    }

    function swap(
        address sender,
        PoolKey memory key,
        IPoolManager.SwapParams memory params
    ) public returns (BalanceDelta delta) {
        delta = poolManager.swap(key, params, abi.encode(""));
        if (params.zeroForOne) {
            if (delta.amount0() > 0) {
                if (key.currency0.isNative()) {
                    poolManager.settle{value: uint128(delta.amount0())}(
                        key.currency0
                    );
                } else {
                    ERC20(Currency.unwrap(key.currency0)).transfer(
                        address(poolManager),
                        uint128(delta.amount0())
                    );
                    poolManager.settle(key.currency0);
                }
            }
            if (delta.amount1() < 0) {
                poolManager.take(
                    key.currency1,
                    sender,
                    uint128(-delta.amount1())
                );
            }
        } else {
            if (delta.amount1() > 0) {
                if (key.currency1.isNative()) {
                    poolManager.settle{value: uint128(delta.amount1())}(
                        key.currency1
                    );
                } else {
                    ERC20(Currency.unwrap(key.currency1)).transfer(
                        address(poolManager),
                        uint128(delta.amount1())
                    );
                    poolManager.settle(key.currency1);
                }
            }
            if (delta.amount0() < 0) {
                poolManager.take(
                    key.currency0,
                    sender,
                    uint128(-delta.amount0())
                );
            }
        }
    }

    function modifyPosition(
        PoolKey memory key,
        IPoolManager.ModifyPositionParams memory params,
        address caller
    ) external returns (BalanceDelta delta) {
        delta = poolManager.modifyPosition(key, params, abi.encode(""));
        if (delta.amount0() > 0) {
            if (key.currency0.isNative()) {
                poolManager.settle{value: uint128(delta.amount0())}(
                    key.currency0
                );
            } else {
                ERC20(Currency.unwrap(key.currency0)).transferFrom(
                    caller,
                    address(poolManager),
                    uint128(delta.amount0())
                );
                poolManager.settle(key.currency0);
            }
        }
        if (delta.amount1() > 0) {
            if (key.currency1.isNative()) {
                poolManager.settle{value: uint128(delta.amount1())}(
                    key.currency1
                );
            } else {
                ERC20(Currency.unwrap(key.currency1)).transferFrom(
                    caller,
                    address(poolManager),
                    uint128(delta.amount1())
                );
                poolManager.settle(key.currency1);
            }
        }

        if (delta.amount0() < 0) {
            poolManager.take(key.currency0, caller, uint128(-delta.amount0()));
        }
        if (delta.amount1() < 0) {
            poolManager.take(key.currency1, caller, uint128(-delta.amount1()));
        }
    }

    receive() external payable {}
}
