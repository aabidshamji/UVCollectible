// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UVCollectible.sol";
import "../src/UVCollectibleV2.sol";
import "../src/UVCollectibleFactory.sol";
import "../src/UVCollectibleBeacon.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

contract BaseSetup is Test {
    UVCollectibleFactory public factory;
    UVCollectibleBeacon public beacon;
    UVCollectible public logic;
    address public proxyAddress;
    UVCollectible public proxied;

    uint256 NUM_COLLECTIONS = 20;

    address public owner;
    address public uvadmin;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    error Unauthorized();

    function setUp() public {
        owner = address(this);
        uvadmin = cheats.addr(1);

        // (1) Create logic contract
        logic = new UVCollectible();

        // (2) Create Factory and save the beacon
        factory = new UVCollectibleFactory(address(logic));
        beacon = UVCollectibleBeacon(factory.getBeacon());

        // (3) Build multiple collectible contracts
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
    }

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

    // function testUpgrade() public {
    //     versionTestHelper(0);
    //     UVCollectibleV2 newLogic = new UVCollectibleV2();
    //    vm.startPrank(address(factory));
    //     beacon.update(address(newLogic));
    //     versionTestHelper(2);
    // }
}

// forge test -vvvv
// forge test --gas-report
