// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {ProteccNft} from "../src/nft/ProteccNft.sol";

contract DeployProteccNft is Script {
    function run() public {
        vm.startBroadcast();

        ProteccNft proteccNft = new ProteccNft(
            0x37909e961860E10de295F6a02AD1b834D00424Ce, // Owner is us
            0xe432150cce91c13a887f7D836923d5597adD8E31 // Axelar Gateway contract on Scroll
        );
        console.log("ProteccNft deployed at: %s", address(proteccNft));

        vm.stopBroadcast();
    }
}
