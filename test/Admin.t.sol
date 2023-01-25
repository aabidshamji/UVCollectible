// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract AdminTest is BaseSetup {
    // check admins
    function testCheckAdmin() public {
        // admin
        assert(proxied.isAdmin(uvadmin));

        // owner is not admin
        assertFalse(proxied.isAdmin(owner));

        // user is not admin
        assertFalse(proxied.isAdmin(user));
    }

    // add and remove admin as owner
    function testUpdateAdminAsOwner() public {
        address newAdmin = cheats.addr(5);
        assertFalse(proxied.isAdmin(newAdmin));
        proxied.addAdmin(newAdmin);
        assert(proxied.isAdmin(newAdmin));
        proxied.removeAdmin(newAdmin);
        assertFalse(proxied.isAdmin(newAdmin));
    }

    // add and remove admin as admin
    function testUpdateAdminAsAdmin() public {
        address newAdmin = cheats.addr(5);
        assertFalse(proxied.isAdmin(newAdmin));
        vm.startPrank(uvadmin);
        proxied.addAdmin(newAdmin);
        assert(proxied.isAdmin(newAdmin));
        proxied.removeAdmin(newAdmin);
        vm.stopPrank();
        assertFalse(proxied.isAdmin(newAdmin));
    }

    // add and remove admin as admin
    function testUpdateAdminAsUser() public {
        address newAdmin = cheats.addr(5);
        assertFalse(proxied.isAdmin(newAdmin));
        vm.startPrank(user);
        vm.expectRevert("caller is not owner or admin");
        proxied.addAdmin(newAdmin);
        assertFalse(proxied.isAdmin(newAdmin));
        vm.expectRevert("caller is not owner or admin");
        proxied.removeAdmin(uvadmin);
        vm.stopPrank();
        assert(proxied.isAdmin(uvadmin));
    }
}
