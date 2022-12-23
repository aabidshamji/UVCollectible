// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ProxyTest.t.sol";
import "../src/UVCollectible.sol";

contract UVCollectableTest is ProxyTest {
    function testName() public {
        assertEq(proxied.name(), "UVCollectible");
        vm.startPrank(uvadmin);
        proxied.updateName("UVCollectibleNew");
        assertEq(proxied.name(), "UVCollectibleNew");
        vm.stopPrank();
    }
}
