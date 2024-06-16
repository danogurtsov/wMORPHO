// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {WMORPHO} from "../src/WMORPHO.sol";

contract WMORPHOTest is Test {
    WMORPHO public wMorpho;
    address morpho = 0x9994E35Db50125E0DF82e4c2dde62496CE330999;
    address rewardDistributor = 0x3B14E5C73e0A56D607A8688098326fD4b4292135;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
        wMorpho = new WMORPHO(morpho, rewardDistributor, "wMORPHO", "wMORPHO");
    }

    function testDeploy() public {
        assertEq(morpho, address(wMorpho.MORPHO()));
        assertEq(wMorpho.MORPHO().totalSupply(), 1000000000000000000000000000);
    }
}
