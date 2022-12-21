// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UVCollectible.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

contract UVCollectableTest is Test {
    UVCollectible public collectible;

    address public owner;
    address public uvadmin;
    address public user;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        owner = address(this);
        uvadmin = cheats.addr(1);
        user = cheats.addr(2);
        collectible = new UVCollectible();
        collectible.transferOwnership(owner);
        // collectible.initialize(
        // "UVCollectible",
        // "UVC",
        // "www.tokens.uv.club/creator/",
        // uvadmin
        // );
    }

    function testName() public {
        vm.startPrank(uvadmin);
        collectible.updateName("UVCollectible");
        assertEq(collectible.name(), "UVCollectible");
        collectible.updateName("UVCollectibleNew");
        assertEq(collectible.name(), "UVCollectibleNew");
        vm.stopPrank();
    }
}
