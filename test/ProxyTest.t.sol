// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UVCollectible.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

contract ProxyTest is Test {
    UVCollectible public logic;
    ERC1967Proxy public proxy;
    UVCollectible public proxied;

    address public owner;
    address public uvadmin;
    address public user;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        owner = address(this);
        uvadmin = cheats.addr(1);
        user = cheats.addr(2);
        // (1) Create logic contract
        logic = new UVCollectible();

        // (2) Create proxy and tell it which logic contract to use
        proxy = new ERC1967Proxy(address(logic), "");

        // (3) To be able to call functions from the logic contract, we need to
        //     cast the proxy to the right type
        proxied = UVCollectible(address(proxy));
        proxied.initialize("UVCollectible", "", "", address(uvadmin));
    }
}
