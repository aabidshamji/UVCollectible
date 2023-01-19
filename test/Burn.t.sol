// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract BurnTest is BaseSetup {
    // Burn only minted tokens
    function testBurn() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(user);
        proxied.burn(newTokenId);
        vm.stopPrank();
        vm.expectRevert("ERC721: invalid token ID");
        proxied.ownerOf(newTokenId);
        // test that we are clearning all the correct fields
        vm.expectRevert("ERC721: invalid token ID");
        proxied.tokenCollection(newTokenId);
        proxied.isLocked(newTokenId);
    }

    // Different user burn
    function testFailBurnUser() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(user1);
        proxied.burn(newTokenId);
        vm.stopPrank();
        address tokenOwner = proxied.ownerOf(newTokenId);
        assertEq(tokenOwner, user);
    }

    // cannot burn non-minted tokens
    function testFailBurn() public {
        vm.startPrank(user);
        proxied.burn(4565);
        vm.stopPrank();
    }

    // cannot burn locked tokens
    function testBurnLocked() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(user);
        vm.expectRevert("Token is locked");
        proxied.burn(newTokenId);
        vm.stopPrank();
        address tokenOwner = proxied.ownerOf(newTokenId);
        assertEq(tokenOwner, user);
    }

    // admin can burn locked tokens
    function testBurnLockedAdmin() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(uvadmin);
        proxied.burnLocked(newTokenId);
        vm.stopPrank();
        vm.expectRevert("ERC721: invalid token ID");
        proxied.ownerOf(newTokenId);
    }

    // admin cannot burn unlocked tokens
    function testBurnUnlockedAdmin() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(uvadmin);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        proxied.burn(newTokenId);
        vm.expectRevert("Token is not locked");
        proxied.burnLocked(newTokenId);
        vm.stopPrank();
        address tokenOwner = proxied.ownerOf(newTokenId);
        assertEq(tokenOwner, user);
    }

    // contract owner can burn locked tokens
    function testBurnLockedOwner() public {
        uint256 newTokenId = proxied.mintToken(0, user, true);
        vm.startPrank(owner);
        proxied.burnLocked(newTokenId);
        vm.stopPrank();
        vm.expectRevert("ERC721: invalid token ID");
        proxied.ownerOf(newTokenId);
    }

    // contract owner cannot burn unlocked tokens
    function testBurnUnlockedOwner() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(owner);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        proxied.burn(newTokenId);
        vm.expectRevert("Token is not locked");
        proxied.burnLocked(newTokenId);
        vm.stopPrank();
        address tokenOwner = proxied.ownerOf(newTokenId);
        assertEq(tokenOwner, user);
    }

    // non admin/owner users cannot call burnLocked
    function testBurnUnlockedUser() public {
        uint256 newTokenId = proxied.mintToken(0, user, false);
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.burnLocked(newTokenId);
        vm.stopPrank();
    }
}
