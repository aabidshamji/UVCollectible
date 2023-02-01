// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UVCollectible.sol";
import "../src/UVCollectibleFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

contract BaseSetup is Test {
    UVCollectibleFactory public factory;
    UVCollectible public logic;
    address public proxyAddress;
    UVCollectible public proxied;

    address public owner;
    address public uvadmin;
    address public user;
    address public user1;
    address public user2;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    error Unauthorized();

    function setUp() public {
        owner = address(this);
        uvadmin = cheats.addr(1);
        user = cheats.addr(2);
        user1 = cheats.addr(3);
        user2 = cheats.addr(4);

        // (1) Create logic contract
        logic = new UVCollectible();

        // (2) Create Factory
        factory = new UVCollectibleFactory(address(logic));

        // (3) Build a collectible contract
        uint256 collectibleId = 1;
        factory.buildCollectible(
            "UVCollectible",
            "UVC",
            "token.ultraviolet.club",
            address(uvadmin),
            collectibleId,
            owner
        );

        // (4) To be able to call functions from the logic contract, we need to
        //     cast the proxy to the right type
        proxyAddress = factory.getCollectibleAddress(collectibleId);
        proxied = UVCollectible(proxyAddress);
    }
}

// forge test -vvvv
// forge test --gas-report
