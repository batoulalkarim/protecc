// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {Protecc} from "../src/Protecc.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {HookMiner} from "../test/utils/libraries/HookMiner.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {ProteccImplementation} from "../src/implementation/ProteccImplementation.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";

library AddressToString {
    function toString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

contract ProteccScript is Script, Deployers {
    using AddressToString for address;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    Protecc public hook;
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {}

    function run(
        address token,
        PoolManager poolManager,
        address destinationAddress
    ) public {
        vm.startBroadcast();
        uint160 flags = uint160(
            Hooks.BEFORE_MODIFY_POSITION_FLAG |
                Hooks.AFTER_MODIFY_POSITION_FLAG |
                Hooks.AFTER_SWAP_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(Protecc).creationCode,
            abi.encode(address(poolManager))
        );

        hook = new Protecc{salt: salt}(
            poolManager,
            0x4F4495243837681061C4743b74B3eEdf548D56A5, // Axelar gateway on mainnet
            0x2d5d7d31F671F86C782533cc367F14109a082712, // Axelar gas receiver on mainnet
            destinationAddress.toString(),
            "scroll"
        );

        require(address(hook) == hookAddress, "Hook address mismatch");

        ProteccImplementation impl = new ProteccImplementation(
            poolManager,
            0x4F4495243837681061C4743b74B3eEdf548D56A5, // Axelar gateway on mainnet
            0x2d5d7d31F671F86C782533cc367F14109a082712, // Axelar gas receiver on mainnet
            destinationAddress.toString(),
            "scroll",
            hook
        );
        address tokenA = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        address tokenB = token;

        address token0 = tokenA < tokenB ? tokenA : tokenB;
        address token1 = tokenA < tokenB ? tokenB : tokenA;

        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60, // Figure out what this should be in the future
            hooks: IHooks(hook)
        });

        poolId = poolKey.toId();
        poolManager.initialize(poolKey, SQRT_RATIO_1_1, abi.encode(""));

        vm.stopBroadcast();
    }
}
