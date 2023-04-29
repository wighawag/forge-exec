// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Exec} from "forge-exec/Exec.sol";

contract ExecDemoScript is Script {
    function setUp() public {}

    function run() public {
        string[] memory args = new string[](0);
        Exec.execute("./target/debug/example", args, true);
    }
}
