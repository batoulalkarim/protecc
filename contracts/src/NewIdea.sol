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
import {Pool} from "@uniswap/v4-core/contracts/libraries/Pool.sol";
import {Position} from "@uniswap/v4-core/contracts/libraries/Position.sol";

// Interafces
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {ISavingsDai} from "./external/sdai/ISavingsDai.sol";

// Open Zeppelin
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Other
import {Constants} from "./libraries/Constants.sol";

// Axelar
import {AxelarExecutable} from "axelar-gmp-sdk-solidity/executable/AxelarExecutable.sol";
import {IAxelarGasService} from "axelar-gmp-sdk-solidity/interfaces/IAxelarGasService.sol";

contract NewIdea is BaseHook, AxelarExecutable {
    using Pool for *;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ISavingsDai public immutable savingsDai =
        ISavingsDai(0x83F20F44975D03b1b09e64809B757c47f942BEeA);

    ERC20 public immutable dai =
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    IAxelarGasService public immutable gasService;

    constructor(
        IPoolManager _poolManager,
        address _gateway,
        address _gasReceiver
    ) BaseHook(_poolManager) AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasReceiver);
    }

    function setRemoteValue(
        string calldata destinationChain,
        string calldata destinationAddress,
        address value_
    ) external payable {
        require(msg.value > 0, "Gas payment is required");

        bytes memory payload = abi.encode(value_);
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

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

    function _handleLiquidityPositions(PoolKey calldata key) private {
        uint256 minDaiRequired;
        uint256 balanceDai = dai.balanceOf(address(this));

        (, int24 tick, , ) = poolManager.getSlot0(key.toId());
        uint128 liquidity = poolManager.getLiquidity(key.toId());
        // Calculate amount for dai and token
        int24 tickLower = _calculateTickLower(tick, key.tickSpacing);
        int24 tickUpper = _calculateTickUpper(tick, key.tickSpacing);

        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint160 sqrtPriceCurrentX96 = TickMath.getSqrtRatioAtTick(tick);

        (uint256 amount0, uint256 amount1) = _calculateAmounts(
            tick,
            tickLower,
            tickUpper,
            sqrtPriceAX96,
            sqrtPriceBX96,
            sqrtPriceCurrentX96,
            liquidity
        );

        if ((key.currency0) == Currency.wrap((address(dai)))) {
            minDaiRequired = amount0;
        } else {
            minDaiRequired = amount1;
        }

        if (minDaiRequired >= balanceDai) {
            // Convert sDai to dai because more is needed for the trade
            _makeDaiAvail(minDaiRequired - balanceDai);
        } else if (minDaiRequired < balanceDai) {
            // Convert some back to sDai and earn yield
            _makeSavingsDai(balanceDai - minDaiRequired);
        }
    }

    function _ensureAmountsForModifyPosition(
        address sender,
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper
    ) private {
        // Need to call getPosition
        // Need pool id, owner, tickLower, tickUpper
        uint256 daiNeededForPosition;
        Position.Info memory position = poolManager.getPosition(
            key.toId(),
            sender,
            tickLower,
            tickUpper
        );
        uint128 liquidity = position.liquidity;
        (, int24 tick, , ) = poolManager.getSlot0(key.toId());
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint160 sqrtPriceCurrentX96 = TickMath.getSqrtRatioAtTick(tick);
        (uint256 amount0, uint256 amount1) = _calculateAmounts(
            tick,
            tickLower,
            tickUpper,
            sqrtPriceAX96,
            sqrtPriceBX96,
            sqrtPriceCurrentX96,
            liquidity
        );
        if ((key.currency0) == Currency.wrap((address(dai)))) {
            daiNeededForPosition = amount0;
        } else {
            daiNeededForPosition = amount1;
        }
        uint256 balanceDai = dai.balanceOf(address(this));
        if (daiNeededForPosition > balanceDai) {
            // Convert sDai to dai because more is needed for the trade
            _makeDaiAvail(daiNeededForPosition - balanceDai);
        }
    }

    function _calculateTickLower(
        int24 actualTick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 tickLowerMultiple = actualTick / tickSpacing;
        if (actualTick < 0 && actualTick % tickSpacing != 0) {
            tickLowerMultiple = tickLowerMultiple - 1; // Implementing floor function for negative numbers
        }
        return tickLowerMultiple * tickSpacing;
    }

    // Calculate the tickUpper given the actualTick and tickSpacing
    function _calculateTickUpper(
        int24 actualTick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 tickUpperMultiple = actualTick / tickSpacing;
        if (actualTick >= 0 && actualTick % tickSpacing != 0) {
            tickUpperMultiple = tickUpperMultiple + 1; // Implementing ceiling function for positive numbers
        }
        return tickUpperMultiple * tickSpacing;
    }

    function _calculateAmounts(
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint160 sqrtPriceCurrentX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (tick < tickLower) {
            amount0 =
                (uint256(liquidity) * (sqrtPriceBX96 - sqrtPriceAX96)) >>
                96;
        } else if (tick >= tickLower && tick < tickUpper) {
            amount0 =
                (uint256(liquidity) * (sqrtPriceBX96 - sqrtPriceCurrentX96)) >>
                96;
            amount1 =
                (uint256(liquidity) * (sqrtPriceCurrentX96 - sqrtPriceAX96)) >>
                96;
        } else if (tick >= tickUpper) {
            amount1 =
                (uint256(liquidity) * (sqrtPriceBX96 - sqrtPriceAX96)) >>
                96;
        }
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24,
        bytes calldata
    ) external override returns (bytes4) {
        _handleLiquidityPositions(key);
        return BaseHook.afterInitialize.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        _handleLiquidityPositions(key);
        return BaseHook.afterSwap.selector;
    }

    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata
    ) external override returns (bytes4) {
        if (params.liquidityDelta < 0) {
            _ensureAmountsForModifyPosition(
                sender,
                key,
                params.tickLower,
                params.tickUpper
            );
            // Need to figure out how to send rewards to the users too
        }
        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        // NOTE: UPDATE THIS FUNCTION
        _handleLiquidityPositions(key);

        return BaseHook.afterModifyPosition.selector;
    }

    /// @notice Function takes a specific amount of sdai and converts to dai because
    // more liquidity is required to make trades
    function _makeDaiAvail(
        uint256 sDaiAmount
    ) private returns (uint256 assets) {
        uint256 sDaiBalance = savingsDai.balanceOf(address(this));
        require(sDaiBalance >= sDaiAmount, "Not enough sDAI");
        assets = savingsDai.redeem(
            sDaiAmount,
            address(this), // reciever
            address(this) // owner
        );
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
