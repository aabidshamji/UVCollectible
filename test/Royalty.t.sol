// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract RoyaltyTest is BaseSetup {
    // default royalty is 0 to address(0)
    function testDefaultAtMint() public {
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(100, user, false);
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // no royalties for tokens that have not been minted
    function testDefaultNotMinted() public {
        address defaultReceiver;
        uint256 defaultAmount;
        vm.expectRevert("ERC721: invalid token ID");
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
    }

    // add and remove default roylaty as user
    function testUpdateDefaultRoyaltyUser() public {
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(100, user, false);

        address newReceiver = owner;
        uint96 newFeeN = 1000; // 10%

        // revert as user
        vm.prank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.setDefaultRoyalty(newReceiver, newFeeN);
        vm.stopPrank();

        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);

        vm.prank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.removeDefaultRoyalty();
        vm.stopPrank();
    }

    // add  and remove default roylaty
    function testUpdateDefaultRoyalty() public {
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(100, user, false);

        address newReceiver = owner;
        uint96 newFeeN = 1000; // 10%

        proxied.setDefaultRoyalty(newReceiver, newFeeN);
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, newReceiver);
        assertEq(defaultAmount, 10);

        proxied.removeDefaultRoyalty();
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add default roylaty - exceed saleprice error
    function testUpdateDefaultRoyaltyExceedPrice() public {
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(100, user, false);

        address newReceiver = owner;
        uint96 newFeeN = 10000 + 1;

        vm.expectRevert("ERC2981: royalty fee will exceed salePrice");
        proxied.setDefaultRoyalty(newReceiver, newFeeN);

        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add default roylaty - invalid receiver error
    function testUpdateDefaultRoyaltyInvalidReceiver() public {
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(100, user, false);

        address newReceiver = address(0);
        uint96 newFeeN = 1000;

        vm.expectRevert("ERC2981: invalid receiver");
        proxied.setDefaultRoyalty(newReceiver, newFeeN);

        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add collection royalty without default
    function testUpdateTokenRoyalty() public {
        uint256 collectionId = 10;
        address defaultReceiver;
        uint256 defaultAmount;
        uint256 newTokenId = proxied.mintToken(collectionId, user, false);

        address newReceiver = owner;
        uint96 newFeeN = 1000; // 10%

        proxied.setCollectionRoyalty(collectionId, newReceiver, newFeeN);
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(newTokenId, 100);
        assertEq(defaultReceiver, newReceiver);
        assertEq(defaultAmount, 10);

        proxied.removeCollectionRoyalty(collectionId);
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(newTokenId, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add collection roylaty - exceed saleprice error
    function testUpdateCollectionRoyaltyExceedPrice() public {
        uint256 collectionId = 10;
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(collectionId, user, false);

        address newReceiver = owner;
        uint96 newFeeN = 10000 + 1;

        vm.expectRevert("ERC2981: royalty fee will exceed salePrice");
        proxied.setCollectionRoyalty(collectionId, newReceiver, newFeeN);

        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add collection roylaty - invalid receiver error
    function testUpdateCollectionRoyaltyInvalidReceiver() public {
        uint256 collectionId = 10;
        address defaultReceiver;
        uint256 defaultAmount;
        proxied.mintToken(collectionId, user, false);

        address newReceiver = address(0);
        uint96 newFeeN = 1000;

        vm.expectRevert("ERC2981: invalid receiver");
        proxied.setCollectionRoyalty(collectionId, newReceiver, newFeeN);

        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(1, 100);
        assertEq(defaultReceiver, address(0));
        assertEq(defaultAmount, 0);
    }

    // add collection royalty without default
    function testUpdateCollectionRoyaltyWithDefault() public {
        uint256 collectionId = 10;
        address defaultReceiver;
        uint256 defaultAmount;
        uint256 newTokenId = proxied.mintToken(collectionId, user, false);

        address newDefaultReceiver = owner;
        uint96 newDefaultFeeN = 1000; // 10%

        address newCollectionReceiver = user1;
        uint96 newCollectionFeeN = 2000; // 20%

        proxied.setDefaultRoyalty(newDefaultReceiver, newDefaultFeeN);

        proxied.setCollectionRoyalty(
            collectionId,
            newCollectionReceiver,
            newCollectionFeeN
        );
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(newTokenId, 100);
        assertEq(defaultReceiver, newCollectionReceiver);
        assertEq(defaultAmount, 20);

        proxied.removeCollectionRoyalty(collectionId);
        (defaultReceiver, defaultAmount) = proxied.royaltyInfo(newTokenId, 100);
        assertEq(defaultReceiver, newDefaultReceiver);
        assertEq(defaultAmount, 10);
    }
}
