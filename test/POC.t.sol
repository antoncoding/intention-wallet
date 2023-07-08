// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IntensionHub} from "../src/IntensionHub.sol";

contract POCTests is Test {
    IntensionHub public hub;

    function setUp() public {
        hub = new IntensionHub();
    }

    function testSwapToken() public {}
}
