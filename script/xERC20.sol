// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {xERC20} from "../src/xERC20.sol";

contract xERC20Script is Script {
    xERC20 public xerc20;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        xerc20 = new xERC20(1000);

        vm.stopBroadcast();
    }
}
