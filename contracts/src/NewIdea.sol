// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// Uniswap V4
import {BaseHook} from "periphery-next/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

// Interafces
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {ISavingsDai} from "./external/sdai/ISavingsDai.sol";

// Open Zeppelin
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Other
import {Constants} from "./libraries/Constants.sol";

contract NewIdea is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ISavingsDai public immutable savingsDai =
        ISavingsDai(0x83F20F44975D03b1b09e64809B757c47f942BEeA);

    ERC20 public immutable dai =
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

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
    ) external override returns (bytes4) {
        if (params.zeroForOne) {
            if (poolKey.currency0 == Currency.wrap(address(dai))) {
                // User is swapping from dai to token
                // Do nothing (handled afterSwap)
            } else {
                // User is swapping from token to dai
                // Take the existing sDAI, unwind it (to DAI; compare with SwapParams) and give it to user
                (, uint256 assets) = _makeDaiAvail();

                require(
                    assets >= uint256(params.amountSpecified),
                    "Not enough assets to trade"
                );
            }
        } else {
            if (poolKey.currency1 == Currency.wrap(address(dai))) {
                // User is swapping from dai to token
                // Do nothing (handled afterSwap)
            } else {
                (, uint256 assets) = _makeDaiAvail();

                require(
                    assets >= uint256(params.amountSpecified),
                    "Not enough assets to trade"
                );
                // DAI is now available to trade
                // Now the swap can take place
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
            if (poolKey.currency0 == Currency.wrap(address(dai))) {
                // User is swapping from dai to token
                // There is now excess dai in this pool, swap it for sDAI
                _convertToSavingsDai();
            } else {
                // User is swapping from token to dai
                // Do nothing
            }
        } else {
            if (poolKey.currency1 == Currency.wrap(address(dai))) {
                // User is swapping from dai to token
                // Do nothing
            } else {
                // User is swapping from token to dai
                // There is now excess dai in this pool, swap it for sDAI
                _convertToSavingsDai();
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

    function _makeDaiAvail() private returns (uint256 shares, uint256 assets) {
        shares = savingsDai.maxWithdraw(
            address(this) // owner
        );

        assets = savingsDai.redeem(
            shares,
            address(this), // reciever
            address(this) // owner
        );
    }

    function _convertToSavingsDai() private returns (uint256 shares) {
        uint256 daiBalance = dai.balanceOf(address(this));
        if (daiBalance > 0) {
            dai.approve(address(savingsDai), daiBalance);
            shares = savingsDai.deposit(daiBalance, address(this));
        }
    }

    receive() external payable {}
}
