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
        perTokenMintTest(newTokenId, user, collectionId, newLocked, 0);
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
}
