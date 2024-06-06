// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {WMORPHO} from "../src/WMORPHO.sol";

contract WMORPHOTest is Test {
    WMORPHO public wMorpho;
    address morpho = 0x9994E35Db50125E0DF82e4c2dde62496CE330999;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
        wMorpho = new WMORPHO(morpho, "wMORPHO", "wMORPHO");
    }

    function testDeploy() public {
        assertNotEq(address(wMorpho), address(0));
        assertEq(morpho, address(wMorpho.MORPHO()));
        console.log(wMorpho.MORPHO().totalSupply());
    }
}
