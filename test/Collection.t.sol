// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract CollectionTest is BaseSetup {
    // minted with collection
    function testCollection() public {
        uint256 collectionId = 0;
        uint256 newTokenId = proxied.mintToken(collectionId, user, true);
        uint256 mintedCollectionId = proxied.tokenCollection(newTokenId);
        assertEq(collectionId, mintedCollectionId);
    }

    // update collection minted
    function testUpdateCollectionMinted() public {
        uint256 collectionId = 0;
        uint256 newTokenId = proxied.mintToken(collectionId, user, true);
        uint256 newCollectionId = 544668;
        proxied.updateTokenCollection(newTokenId, newCollectionId);
        uint256 mintedCollectionId = proxied.tokenCollection(newTokenId);
        assertEq(newCollectionId, mintedCollectionId);
    }

    // update collection not minted
    function testUpdateCollectionNotMinted() public {
        uint256 tokenId = 23;
        uint256 newCollectionId = 544668;
        vm.expectRevert("ERC721: invalid token ID");
        proxied.updateTokenCollection(tokenId, newCollectionId);
    }

    // update collection user
    function testUpdateCollectionUser() public {
        uint256 collectionId = 0;
        uint256 newTokenId = proxied.mintToken(collectionId, user, true);
        uint256 newCollectionId = 544668;
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.updateTokenCollection(newTokenId, newCollectionId);
        vm.stopPrank();
        uint256 mintedCollectionId = proxied.tokenCollection(newTokenId);
        assertEq(collectionId, mintedCollectionId);
    }
}
