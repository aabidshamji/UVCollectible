// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseSetup.sol";
import "../src/UVCollectibleV2.sol";

contract UpgradeTest is BaseSetup {
    uint256 NUM_COLLECTIONS = 20;

    function versionTestHelper(uint256 versionCheck) public {
        for (
            uint256 collectibleId = 0;
            collectibleId < NUM_COLLECTIONS;
            collectibleId++
        ) {
            proxyAddress = factory.getCollectibleAddress(collectibleId);
            proxied = UVCollectible(proxyAddress);
            uint256 proxiedVersion = proxied.VERSION();
            assertEq(proxiedVersion, versionCheck);
        }
    }

    function testUpgrade() public {
        // Build multiple collectible contracts
        for (
            uint256 collectibleId = 0;
            collectibleId < NUM_COLLECTIONS;
            collectibleId++
        ) {
            factory.buildCollectible(
                "UVCollectible",
                "UVC",
                "token.ultraviolet.club",
                address(uvadmin),
                collectibleId,
                owner
            );
        }
        versionTestHelper(0);
        UVCollectibleV2 newLogic = new UVCollectibleV2();
        beacon.update(address(newLogic));
        versionTestHelper(2);
    }
}
