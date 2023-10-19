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
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4) {
        // Regardless of what is happening, need to make DAI available
        // so that the amounts in and out are calculated properly
        (, uint256 assets) = _makeDaiAvail();
        require(
            assets >= uint256(params.amountSpecified),
            "Not enough assets to trade"
        );

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        _makeSavingsDai();
        return BaseHook.afterSwap.selector;
    }

    function beforeModifyPosition(
        address,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata
    ) external override returns (bytes4) {
        if (params.liquidityDelta < 0) {
            // They are removing liquidity
            // Make DAI available and let them remove
            _makeDaiAvail();
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
        // There is either less or more dai
        // Now convert everything back to savings dai
        _makeSavingsDai();

        return BaseHook.afterModifyPosition.selector;
    }

    function _makeDaiAvail() private returns (uint256 shares, uint256 assets) {
        shares = savingsDai.maxWithdraw(
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

    function _makeSavingsDai() private returns (uint256 shares) {
        uint256 daiBalance = dai.balanceOf(address(this));
        if (daiBalance > 0) {
            dai.approve(address(savingsDai), daiBalance);
            shares = savingsDai.deposit(daiBalance, address(this));
        }
    }

    receive() external payable {}
}
