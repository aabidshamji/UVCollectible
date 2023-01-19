// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MintTest is BaseSetup {
    function testMint() public {
        uint256 collectionId = 5;
        uint256 newTokenId = proxied.lastId() + 1;

        vm.startPrank(uvadmin);
        uint256 returnedTokenId = proxied.mintToken(collectionId, user, false);
        vm.stopPrank();

        assertEq(newTokenId, returnedTokenId);

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
