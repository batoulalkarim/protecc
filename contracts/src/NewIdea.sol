// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// Uniswap V4
import {BaseHook} from "periphery-next/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

// Interafces
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {ISavingsDai} from "./external/sdai/ISavingsDai.sol";

// Open Zeppelin
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Other
import {Constants} from "./libraries/Constants.sol";

contract NewIdea is BaseHook {
    // Note: Figure out how to store out of range DAI
    // as sDAI and then roll them back into DAI at nearby ticks

    // Which means we'll have a balance of sDAI and a balance of DAI
    // Need to check the ticks at every swap to see what the deal is and
    // based on that, convert the sDAI to DAI or vice versa

    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // If the pool is in this range, ensure we have enough dai to trade
    mapping(PoolId poolId => int24 tickLower) public tickLowerLast;
    mapping(PoolId poolId => int24 tickUpper) public tickUpperLast;

    uint256 public constant PRECISION = 1e18;

    ISavingsDai public immutable savingsDai =
        ISavingsDai(0x83F20F44975D03b1b09e64809B757c47f942BEeA);

    ERC20 public immutable dai =
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: true,
                beforeModifyPosition: true,
                afterModifyPosition: true,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function _setTickLowerLast(PoolId poolId, int24 tickLower) private {
        tickLowerLast[poolId] = tickLower;
    }

    function _setTickHigherLast(PoolId poolId, int24 tickUpper) private {
        tickUpperLast[poolId] = tickUpper;
    }

    function _getTickLower(
        int24 actualTick,
        int24 tickSpacing
    ) private pure returns (int24) {
        int24 intervals = actualTick / tickSpacing;
        if (actualTick < 0 && (actualTick % tickSpacing != 0)) {
            intervals--;
        }

        return intervals * tickSpacing;
    }

    function _getTickUpper(
        int24 actualTick,
        int24 tickSpacing
    ) private pure returns (int24) {
        int24 intervals = actualTick / tickSpacing;
        if (actualTick >= 0 && (actualTick % tickSpacing != 0)) {
            intervals++;
        }

        return intervals * tickSpacing;
    }

    function _calculateIntervals(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) private pure returns (int24) {
        require(tickSpacing > 0, "tickSpacing should be positive");
        require(
            tickUpper >= tickLower,
            "tickUpper should be greater than or equal to tickLower"
        );

        int24 intervals = (tickUpper - tickLower) / tickSpacing;

        return intervals;
    }

    function _calculateRatio(
        int24 currentIntervals,
        int24 maxIntervals
    ) private pure returns (uint256) {
        // Note: add checks

        uint256 ratio = (int24ToUint256(currentIntervals) * PRECISION) /
            int24ToUint256(maxIntervals);

        return ratio;
    }

    function int24ToUint256(int24 value) public pure returns (uint256) {
        require(value >= 0, "Cannot convert negative int24 to uint256");

        // Convert int24 to int256 first
        int256 intermediateValue = int256(value);

        // Then convert int256 to uint256
        return uint256(intermediateValue);
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24 tick,
        bytes calldata
    ) external override returns (bytes4) {
        _setTickLowerLast(key.toId(), _getTickLower(tick, key.tickSpacing));
        _setTickHigherLast(key.toId(), _getTickUpper(tick, key.tickSpacing));
        return BaseHook.afterInitialize.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        int24 lastTickLower = tickLowerLast[key.toId()];
        int24 lastTickUpper = tickUpperLast[key.toId()];
        (, int24 currentTick, , ) = poolManager.getSlot0(key.toId());
        int24 currentTickLower = _getTickLower(currentTick, key.tickSpacing);
        int24 currentTickUpper = _getTickUpper(currentTick, key.tickSpacing);

        int24 intervalsCurrent = _calculateIntervals(
            currentTickLower,
            currentTickUpper,
            key.tickSpacing
        );
        int24 intervalsMax = _calculateIntervals(
            TickMath.MIN_TICK,
            TickMath.MAX_TICK,
            key.tickSpacing
        );

        uint256 ratio = _calculateRatio(intervalsCurrent, intervalsMax);
        uint256 daiBalance = dai.balanceOf(address(this));
        uint256 sDaiBalance = savingsDai.balanceOf(address(this));

        // Lazy
        uint256 totalDai = daiBalance + sDaiBalance;
        uint256 targetSDai = (totalDai * ratio) / PRECISION;

        // Need to handle ticks that are the same (current versus last)

        if (
            currentTickLower < lastTickLower && currentTickUpper > lastTickUpper
        ) {
            // Need to convert sdai back to dai ONLY
            _makeDaiAvail(targetSDai - sDaiBalance);
        }

        if (
            (currentTickLower < lastTickLower &&
                currentTickUpper < lastTickUpper) ||
            (currentTickLower > lastTickLower &&
                currentTickUpper > lastTickUpper) ||
            (currentTickLower == lastTickLower &&
                currentTickUpper > lastTickUpper) ||
            (currentTickLower < lastTickLower &&
                currentTickUpper == lastTickUpper)
        ) {
            // Left increasing, right are decreasing
            if (targetSDai > sDaiBalance) {
                _makeDaiAvail(targetSDai - sDaiBalance);
            }
        }

        if (
            (currentTickLower > lastTickLower &&
                currentTickUpper < lastTickUpper) ||
            (currentTickLower == lastTickLower &&
                currentTickUpper < lastTickUpper) ||
            (currentTickLower > lastTickLower &&
                currentTickUpper == lastTickUpper)
        ) {
            // Need to convert
            _makeSavingsDai(sDaiBalance - targetSDai);
        }

        return BaseHook.afterSwap.selector;
    }

    function beforeModifyPosition(
        address,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata
    ) external override returns (bytes4) {
        // NOTE: UPDATE THIS FUNCTION
        if (params.liquidityDelta < 0) {
            // They are removing liquidity
            // Make DAI available and let them remove
            _makeDaiAvail(1);
        }
        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        // NOTE: UPDATE THIS FUNCTION

        // There is either less or more dai
        // Now convert everything back to savings dai

        return BaseHook.afterModifyPosition.selector;
    }

    /// @notice Function takes a specific amount of sdai and converts to dai because
    // more liquidity is required to make trades
    function _makeDaiAvail(
        uint256 sDaiAmount
    ) private returns (uint256 shares, uint256 assets) {
        // NOTE: UPDATE THIS FUNCTION

        shares = savingsDai.withdraw(
            sDaiAmount,
            address(this), // receiver
            address(this) // owner
        );
        // Need to figure out if this is the best way to do it... seems lazy
        assets = savingsDai.redeem(
            shares,
            address(this), // reciever
            address(this) // owner
        );
        // Ideally should only make the DAI that is being deposited available
        // so that the price of the paired token does not get skewed incorrectly
        // Note: When we redeem, we should isolate deposited DAI and earned DAI
    }

    /// @notice Function takes in a specific amount of dai now and converts to sdai
    function _makeSavingsDai(
        uint256 daiAmount
    ) private returns (uint256 shares) {
        uint256 daiBalance = dai.balanceOf(address(this));
        require(daiBalance >= daiAmount, "Not enough DAI");
        if (daiAmount > 0) {
            dai.approve(address(savingsDai), daiAmount);
            shares = savingsDai.deposit(daiAmount, address(this));
        }
    }

    receive() external payable {}
}
