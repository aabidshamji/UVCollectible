// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract UVCollectableTest is BaseSetup {
    function testName() public {
        assertEq(proxied.name(), "UVCollectible");
        vm.startPrank(uvadmin);
        proxied.updateName("UVCollectibleNew");
        assertEq(proxied.name(), "UVCollectibleNew");
        vm.stopPrank();
    }

    function testFailName() public {
        vm.startPrank(user);
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

    function testFailSymbol() public {
        vm.startPrank(user);
        proxied.updateSymbol("UVC");
        vm.stopPrank();
    }

    function testMint() public {
        uint256 collectionId = 5;
        uint256 newTokenId = proxied.lastId() + 1;

        vm.startPrank(uvadmin);
        proxied.mintToken(collectionId, user, false, 0);
        vm.stopPrank();

        address newOwner = proxied.ownerOf(newTokenId);
        assertEq(newOwner, user);

        uint256 newTokenCollection = proxied.tokenCollection(newTokenId);
        assertEq(newTokenCollection, collectionId);

        string memory newTokenURI = proxied.tokenURI(newTokenId);
        string memory contractURI = proxied.contractURI();

        string memory correctURI = string(
            abi.encodePacked(
                contractURI,
                StringsUpgradeable.toString(collectionId),
                "/",
                StringsUpgradeable.toString(newTokenId)
            )
        );
        assertEq(newTokenURI, correctURI);
    }
}
