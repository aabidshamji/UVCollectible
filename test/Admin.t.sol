// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract AdminTest is BaseSetup {
    function testName() public {
        assertEq(proxied.name(), "UVCollectible");
        vm.startPrank(uvadmin);
        proxied.updateName("UVCollectibleNew");
        assertEq(proxied.name(), "UVCollectibleNew");
        vm.stopPrank();
    }

    function testFailName() public {
        vm.startPrank(user);
        proxied.updateName("UVCollectibleNew");
        vm.stopPrank();
    }

    function testSymbol() public {
        assertEq(proxied.symbol(), "UVC");
        vm.startPrank(uvadmin);
        proxied.updateSymbol("nUVC");
        assertEq(proxied.symbol(), "nUVC");
        vm.stopPrank();
    }

    function testFailSymbol() public {
        vm.startPrank(user);
        proxied.updateSymbol("UVC");
        vm.stopPrank();
    }
}
