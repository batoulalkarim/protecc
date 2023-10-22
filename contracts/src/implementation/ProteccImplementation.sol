// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Protecc} from "../Protecc.sol";

import {BaseHook} from "periphery-next/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

contract ProteccImplementation is Protecc {
    constructor(
        IPoolManager manager,
        address gateway,
        address gasReceiver,
        string memory destinationAddress,
        string memory destinationChain,
        Protecc addressToEtch
    )
        Protecc(
            manager,
            gateway,
            gasReceiver,
            destinationAddress,
            destinationChain
        )
    {
        Hooks.validateHookAddress(addressToEtch, getHooksCalls());
    }

    function validateHookAddress(BaseHook _this) internal pure override {}
}
