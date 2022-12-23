// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

contract ProxyTest is Test {

    UVCollectible implementation = new UVCollectible();
    
    ERC1967UpgradeUpgradeable proxy = new ERC1967UpgradeUpgradeable();

}