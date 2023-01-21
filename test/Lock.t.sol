// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract LockTest is BaseSetup {
    // token can be minted locked
    function testMintLocked() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        bool isLocked = proxied.isLocked(newTokenId);
        assert(isLocked);
    }

    // tokens minted unlocked
    function testMintUnlocked() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        bool isLocked = proxied.isLocked(newTokenId);
        assert(!isLocked);
    }

    // locked tokens cannot be transfered
    function testLockedTransfer() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(user);
        vm.expectRevert("Token is locked");
        proxied.transferFrom(user, user1, newTokenId);
        vm.stopPrank();
    }

    // admin can transfer locked tokens
    function testLockedTransferAdmin() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(uvadmin);
        // locked after transfer
        proxied.transferLockedToken(newTokenId, user1, true);
        assertEq(user1, proxied.ownerOf(newTokenId));
        assert(proxied.isLocked(newTokenId));
        // unlocked after transfer
        proxied.transferLockedToken(newTokenId, user2, false);
        assertEq(user2, proxied.ownerOf(newTokenId));
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // owner can transfer locked tokens
    function testLockedTransferOwner() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(owner);
        // locked after transfer
        proxied.transferLockedToken(newTokenId, user1, true);
        assertEq(user1, proxied.ownerOf(newTokenId));
        assert(proxied.isLocked(newTokenId));
        // unlocked after transfer
        proxied.transferLockedToken(newTokenId, user2, false);
        assertEq(user2, proxied.ownerOf(newTokenId));
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // user can lock minted token if owner of token
    function testLockMintedUser() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(user);
        proxied.lockToken(newTokenId);
        assert(proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // user cannot unlock token
    function testUnlockMintedUser() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.unlockToken(newTokenId);
        assert(proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // admin cannot lock minted token
    function testLockMintedAdmin() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(uvadmin);
        vm.expectRevert("caller is not token owner or approved");
        proxied.lockToken(newTokenId);
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // owner cannot lock minted token
    function testLockMintedOwer() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(owner);
        vm.expectRevert("caller is not token owner or approved");
        proxied.lockToken(newTokenId);
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // admin can unlock token
    function testUnlockMintedAdmin() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(uvadmin);
        proxied.unlockToken(newTokenId);
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }

    // owner can unlock token
    function testUnlockMintedOwner() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(owner);
        proxied.unlockToken(newTokenId);
        assert(!proxied.isLocked(newTokenId));
        vm.stopPrank();
    }
}
