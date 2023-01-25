// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MetadataTest is BaseSetup {
    function testName() public {
        assertEq(proxied.name(), "UVCollectible");
        vm.startPrank(uvadmin);
        proxied.updateName("UVCollectibleNew");
        assertEq(proxied.name(), "UVCollectibleNew");
        vm.stopPrank();
    }

    function testUpdateNameUser() public {
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
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

    function testUpdateSymbolUser() public {
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.updateSymbol("UVC");
        vm.stopPrank();
    }

    function testContractURI() public {
        assertEq("token.ultraviolet.club", proxied.contractURI());
        string memory newContractURI = "new.ultraviolet.club";
        proxied.updateContractURI(newContractURI);
        assertEq(newContractURI, proxied.contractURI());
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.updateContractURI("user.ultraviolet.club");
        assertEq(newContractURI, proxied.contractURI());
    }

    function testCollectionURI() public {
        uint256 collectionId = 999;
        assertEq(
            "token.ultraviolet.club/999",
            proxied.collectionURI(collectionId)
        );
    }

    function testTokenURI() public {
        uint256 newTokenId = proxied.mintToken(999, user, false);
        string memory tokenURI = proxied.tokenURI(newTokenId);
        assertEq(tokenURI, "token.ultraviolet.club/999/1");
        uint256 newCollectionId = 10;
        proxied.updateTokenCollection(newTokenId, newCollectionId);
        string memory newTokenURI = proxied.tokenURI(newTokenId);
        assertEq(newTokenURI, "token.ultraviolet.club/10/1");
    }

    // last id starts at 0 at after deploy
    function testSetLast() public {
        assertEq(proxied.lastId(), 0);
        proxied.mintToken(999, user, false);
        assertEq(proxied.lastId(), 1);
        proxied.setLastId(10);
        assertEq(proxied.lastId(), 10);
        uint256 newTokenId = proxied.mintToken(999, user, false);
        assertEq(newTokenId, 11);
        vm.expectRevert("New Id has to be higher");
        proxied.setLastId(5);
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.setLastId(1000);
        assertEq(proxied.lastId(), 11);
    }
}
