// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {NewIdea} from "../NewIdea.sol";

import {BaseHook} from "periphery-next/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

contract NewIdeaImplementation is NewIdea {
    constructor(
        IPoolManager manager,
        address gateway,
        address gasReceiver,
        NewIdea addressToEtch
    ) NewIdea(manager, gateway, gasReceiver) {
        Hooks.validateHookAddress(addressToEtch, getHooksCalls());
    }

    function validateHookAddress(BaseHook _this) internal pure override {}
}
