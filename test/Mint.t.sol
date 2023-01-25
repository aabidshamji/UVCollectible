// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MintTest is BaseSetup {
    // Tests per mint helper
    function perTokenMintTest(
        uint256 tokenId,
        address expOwner,
        uint256 expCollectionId,
        bool expLocked,
        uint64 expExpiration
    ) internal {
        // correct owner
        address newOwner = proxied.ownerOf(tokenId);
        assertEq(newOwner, expOwner);

        // correct collection
        uint256 newTokenCollection = proxied.tokenCollection(tokenId);
        assertEq(newTokenCollection, expCollectionId);

        // correct locked
        bool newLocked = proxied.isLocked(tokenId);
        assertEq(newLocked, expLocked);

        // correct expiration
        uint64 newExpiration = proxied.expiresAt(tokenId);
        assertEq(newExpiration, expExpiration);

        // correct URI
        string memory newTokenURI = proxied.tokenURI(tokenId);
        string memory contractURI = proxied.contractURI();

        string memory correctURI = string(
            abi.encodePacked(
                contractURI,
                StringsUpgradeable.toString(expCollectionId),
                "/",
                StringsUpgradeable.toString(tokenId)
            )
        );
        assertEq(newTokenURI, correctURI);
    }

    // admin and owner can mint (unlocked)
    function testMint() public {
        uint256 collectionId = 5;
        uint256 newTokenId = proxied.lastId() + 1;
        bool newLocked = false;
        uint256 returnedTokenId = proxied.mintToken(
            collectionId,
            user,
            newLocked
        );
        assertEq(newTokenId, returnedTokenId);
        perTokenMintTest(newTokenId, user, collectionId, newLocked, 0);
    }

    // admin and owner can mint (locked)
    function testMintLocked() public {
        uint256 collectionId = 5;
        uint256 newTokenId = proxied.lastId() + 1;
        bool newLocked = true;
        uint256 returnedTokenId = proxied.mintToken(
            collectionId,
            user,
            newLocked
        );
        assertEq(newTokenId, returnedTokenId);
        perTokenMintTest(newTokenId, user, collectionId, newLocked, 0);
    }

    // subscription token mint
    function testMintWithExpiration() public {
        uint256 collectionId = 5;
        uint256 newTokenId = proxied.lastId() + 1;
        bool newLocked = true;
        uint64 newExpiration = 8420241;
        uint256 returnedTokenId = proxied.mintTokenWithExpiration(
            collectionId,
            user,
            newLocked,
            newExpiration
        );
        assertEq(newTokenId, returnedTokenId);
        perTokenMintTest(
            newTokenId,
            user,
            collectionId,
            newLocked,
            newExpiration
        );
    }

    // users cannot mint
    function testMintUser() public {
        uint256 collectionId = 5;
        bool newLocked = false;
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.mintToken(collectionId, user, newLocked);
        vm.stopPrank();
    }

    // mint to many users
    function testMintToManyUsers() public {
        uint256 collectionId = 5;
        address[] memory to = new address[](3);
        to[0] = user;
        to[1] = user1;
        to[2] = user2;
        uint256 newLast;
        uint256 numMinted;
        uint64 expiration = 274729;

        // unlocked + sub
        (newLast, numMinted) = proxied.mintCollectionToManyUsers(
            collectionId,
            to,
            false,
            expiration
        );
        assertEq(newLast, 3);
        assertEq(numMinted, 3);
        for (uint256 i = 0; i < to.length; i++) {
            perTokenMintTest(i + 1, to[i], collectionId, false, expiration);
        }

        // locked = no sub
        (newLast, numMinted) = proxied.mintCollectionToManyUsers(
            collectionId,
            to,
            true,
            0
        );
        assertEq(newLast, 3 + 3);
        assertEq(numMinted, 3);
        for (uint256 i = 0; i < to.length; i++) {
            perTokenMintTest(i + 1 + 3, to[i], collectionId, true, 0);
        }
    }

    // user cannot mint to many
    function testMintToManyUsersAsUser() public {
        uint256 collectionId = 5;
        address[] memory to = new address[](3);
        to[0] = user;
        to[1] = user1;
        to[2] = user2;
        uint256 newLast;
        uint256 numMinted;
        uint64 expiration = 274729;

        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        (newLast, numMinted) = proxied.mintCollectionToManyUsers(
            collectionId,
            to,
            false,
            expiration
        );
    }

    // mint user to many collections
    function testMintUserToManyCollections() public {
        uint256[] memory collectionIds = new uint256[](3);
        collectionIds[0] = 1;
        collectionIds[1] = 2;
        collectionIds[2] = 3;
        uint256 newLast;
        uint256 numMinted;
        uint64 expiration = 274729;

        // unlocked + sub
        (newLast, numMinted) = proxied.mintUserToManyCollections(
            collectionIds,
            user,
            false,
            expiration
        );
        assertEq(newLast, 3);
        assertEq(numMinted, 3);
        assertEq(proxied.balanceOf(user), 3);
        for (uint256 i = 0; i < collectionIds.length; i++) {
            perTokenMintTest(i + 1, user, collectionIds[i], false, expiration);
        }

        // locked = no sub
        (newLast, numMinted) = proxied.mintUserToManyCollections(
            collectionIds,
            user,
            true,
            0
        );
        assertEq(newLast, 3 + 3);
        assertEq(numMinted, 3);
        assertEq(proxied.balanceOf(user), 3 + 3);
        for (uint256 i = 0; i < collectionIds.length; i++) {
            perTokenMintTest(i + 1 + 3, user, collectionIds[i], true, 0);
        }
    }

    // user cannot mint
    function testMintUserToManyCollectionsAsUser() public {
        uint256[] memory collectionIds = new uint256[](3);
        collectionIds[0] = 1;
        collectionIds[1] = 2;
        collectionIds[2] = 3;
        uint256 newLast;
        uint256 numMinted;
        uint64 expiration = 274729;

        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        (newLast, numMinted) = proxied.mintUserToManyCollections(
            collectionIds,
            user,
            false,
            expiration
        );
    }
}
