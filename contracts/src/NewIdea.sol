// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {BaseHook} from "periphery-next/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

import {Constants} from "./libraries/Constants.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NewIdea is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    address public immutable savingsDai = (
        0x83F20F44975D03b1b09e64809B757c47f942BEeA
    );
    address public immutable dai = (0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: true,
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
        if (params.zeroForOne) {
            if (poolKey.currency0 == dai) {
                // User is swapping from dai to token
                // Do nothing (handled afterSwap)
            } else {
                // User is swapping from token to dai
                // Take the existing sDAI, unwind it (to DAI; compare with SwapParams) and give it to user
                // Whatever is left, convert it back to sDAI
            }
        } else {
            if (poolKey.currency1 == dai) {
                // User is swapping from dai to token
                // Do nothing (handled afterSwap)
            } else {
                // User is swapping from token to dai
                // Take the existing sDAI, unwind it (to DAI; compare with SwapParams) and give it to user
                // Whatever is left, convert it back to sDAI
            }
        }

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        if (params.zeroForOne) {
            if (poolKey.currency0 == dai) {
                // User is swapping from dai to token
                // There is now excess dai in this pool, swap it for sDAI
            } else {
                // User is swapping from token to dai
                // Do nothing
            }
        } else {
            if (poolKey.currency1 == dai) {
                // User is swapping from dai to token
                // Do nothing
            } else {
                // User is swapping from token to dai
                // There is now excess dai in this pool, swap it for sDAI
            }
        }
        return BaseHook.afterSwap.selector;
    }

    function beforeModifyPosition(
        address sender,
        PoolKey calldata poolKey,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata hookData
    ) external view override returns (bytes4) {
        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        PoolKey calldata poolKey,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        return BaseHook.afterModifyPosition.selector;
    }

    receive() external payable {}
}
