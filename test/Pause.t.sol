// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract PauseTest is BaseSetup {
    // admin can pause and unpause
    function testPauseAdmin() public {
        assert(!proxied.paused());
        vm.startPrank(uvadmin);

        proxied.pause();
        assert(proxied.paused());

        proxied.unpause();
        assert(!proxied.paused());

        vm.stopPrank();
    }

    // owner can pause and unpause
    function testPauseOwner() public {
        assert(!proxied.paused());
        vm.startPrank(owner);

        proxied.pause();
        assert(proxied.paused());

        proxied.unpause();
        assert(!proxied.paused());

        vm.stopPrank();
    }

    // user cannot pause or unpause
    function testPauseUser() public {
        assert(!proxied.paused());

        // cannot pause
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.pause();
        assert(!proxied.paused());
        vm.stopPrank();

        // admin pause
        vm.startPrank(uvadmin);
        proxied.pause();
        assert(proxied.paused());
        vm.stopPrank();

        // cannot unpause
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.unpause();
        vm.stopPrank();
        assert(proxied.paused());
    }

    // cannot update last id
    function testUpdateLastId() public {
        proxied.pause();
        vm.expectRevert("Pausable: paused");
        proxied.setLastId(382);
    }

    // cannot update token collection
    function testUpdateCollection() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        proxied.pause();
        vm.expectRevert("Pausable: paused");
        proxied.updateTokenCollection(newTokenId, 5);
        assertEq(proxied.tokenCollection(newTokenId), 0);
    }

    // cannot lock token
    function testLockToken() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        proxied.pause();
        vm.startPrank(user);
        vm.expectRevert("Pausable: paused");
        proxied.lockToken(newTokenId);
        vm.stopPrank();
        assert(!proxied.isLocked(newTokenId));
    }

    // cannot unlock token
    function testUnlockToken() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        proxied.pause();
        vm.startPrank(uvadmin);
        vm.expectRevert("Pausable: paused");
        proxied.unlockToken(newTokenId);
        vm.stopPrank();
        assert(proxied.isLocked(newTokenId));
    }

    // cannot mint when paused
    function testMint() public {
        proxied.pause();
        vm.startPrank(uvadmin);
        vm.expectRevert("Pausable: paused");
        proxied.mintToken(0, user, true);
        vm.stopPrank();
    }

    // cannot transfer when paused
    function testTransfer() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        proxied.pause();
        vm.startPrank(user);
        vm.expectRevert("Pausable: paused");
        proxied.transferFrom(user, user1, newTokenId);
        vm.stopPrank();
        assertEq(proxied.ownerOf(newTokenId), user);
    }

    // cannot reclaim when paused
    function testReclaim() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        proxied.pause();
        vm.expectRevert("Pausable: paused");
        proxied.transferLockedToken(newTokenId, user1, false);
        assertEq(proxied.ownerOf(newTokenId), user);
    }
}
