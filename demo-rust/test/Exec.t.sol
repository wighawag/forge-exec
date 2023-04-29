// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Exec} from "forge-exec/Exec.sol";

contract ExecTest is Test {
    function setUp() public {
        string[] memory args = new string[](0);
        bytes memory test = Exec.execute("./target/debug/example", args, false);
        (address addr1, address addr2, address addr3) = abi.decode(
            test,
            (address, address, address)
        );

        console.log("----");
        console.log(addr1, addr2, addr3);
        console.logBytes(test);
        console.log("----");
    }

    function testDeplyment() public view {
        bytes memory code = 0xB318d82866cd9f7d7a55dbbF0a80f787B72BF97C.code;
        assert(code.length > 0);
    }

    function testDeplymentAgain() public view {
        bytes memory code = 0xB318d82866cd9f7d7a55dbbF0a80f787B72BF97C.code;
        assert(code.length > 0);
    }

    function testDeplymentAgainAndAgain() public view {
        bytes memory code = 0xB318d82866cd9f7d7a55dbbF0a80f787B72BF97C.code;
        assert(code.length > 0);
    }

    function testDeplymentAgainAndAgainAndAgain() public view {
        bytes memory code = 0xB318d82866cd9f7d7a55dbbF0a80f787B72BF97C.code;
        assert(code.length > 0);
    }
}
