// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SubscriptionTest is BaseSetup {
    uint256 tokenId = 1;
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    // mints without subscription
    function testMintWithExpiration() public {
        uint256 newTokenId = proxied.mintTokenWithExpiration(
            10,
            user,
            false,
            10000
        );
        assertEq(proxied.expiresAt(newTokenId), 10000);
    }

    // mints without subscription
    function testMintWithoutExpiration() public {
        uint256 newTokenId = proxied.mintToken(10, user, false);
        assertEq(proxied.expiresAt(newTokenId), 0);
    }

    // update subscription
    function testUpdateExpiration() public {
        uint256 newTokenId = proxied.mintToken(10, user, false);
        proxied.setExpiration(newTokenId, 10000);
        assertEq(proxied.expiresAt(newTokenId), 10000);
    }

    // renew subscription
    function testRenewSub() public {
        uint64 expiresAt = 10000;
        uint256 newTokenId = proxied.mintTokenWithExpiration(
            10,
            user,
            false,
            expiresAt
        );
        uint64 renewalTime = 100;
        proxied.renewSubscription(newTokenId, renewalTime);
        assertEq(proxied.expiresAt(newTokenId), expiresAt + renewalTime);
    }

    // renew subscription as user
    function testRenewSubUser() public {
        uint64 expiresAt = 10000;
        uint256 newTokenId = proxied.mintTokenWithExpiration(
            10,
            user,
            false,
            expiresAt
        );
        uint64 renewalTime = 100;
        vm.prank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.renewSubscription(newTokenId, renewalTime);
        assertEq(proxied.expiresAt(newTokenId), expiresAt);
    }

    // admin/owner can cancel subscription
    function testCancelSub() public {
        uint64 expiresAt = 10000;
        uint256 newTokenId = proxied.mintTokenWithExpiration(
            10,
            user,
            false,
            expiresAt
        );
        assertEq(proxied.expiresAt(newTokenId), expiresAt);
        proxied.cancelSubscription(newTokenId);
        assertEq(proxied.expiresAt(newTokenId), 0);
    }

    // isRenewable always true
    function testIsRenewable() public view {
        assert(proxied.isRenewable(0));
    }

    // expiration can only be set for minted tokens
    function testExpirationRevert() public {
        vm.expectRevert("ERC721: invalid token ID");
        proxied.setExpiration(1, 10000);
    }

    // user can cancel
    function testCancelValidUser() public {
        proxied.mintToken(10, user1, false);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 0);
        proxied.cancelSubscription(tokenId);
    }

    // admin can cancel
    function testCancelValidAdmin() public {
        proxied.mintToken(10, user1, false);
        vm.prank(uvadmin);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 0);
        proxied.cancelSubscription(tokenId);
    }

    // other users cannot cancel
    function testCancelNotOwner() public {
        proxied.mintToken(10, user1, false);
        vm.prank(user2);
        vm.expectRevert("Caller is not owner nor approved");
        proxied.cancelSubscription(tokenId);
    }
}
