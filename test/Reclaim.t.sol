// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract ReclaimTest is BaseSetup {
    // locked token can be reclaimed
    function testReclaimLocked() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        proxied.transferLockedToken(newTokenId, user1, false);
        assertEq(proxied.ownerOf(newTokenId), user1);
    }

    // unlocked tokens cannot be reclaimed
    function testReclaimUnlocked() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.expectRevert("Token is not locked");
        proxied.transferLockedToken(newTokenId, user1, false);
        assertEq(proxied.ownerOf(newTokenId), user);
    }

    // users cannot reclaim unlocked tokens
    function testReclaimLockedUser() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.transferLockedToken(newTokenId, user1, false);
        vm.stopPrank();
        assertEq(proxied.ownerOf(newTokenId), user);
    }
}
