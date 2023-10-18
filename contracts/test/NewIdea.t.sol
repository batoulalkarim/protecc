// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {NewIdea} from "../src/NewIdea.sol";
import {HookTest} from "./utils/Hook.t.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";

contract NewIdeaTest is HookTest, Deployers, GasSnapshot {}
