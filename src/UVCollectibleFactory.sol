// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./UVCollectibleBeacon.sol";
import "./UVCollectible.sol";

contract UVCollectibleFactory is Ownable {
    // Contract version
    uint256 public constant VERSION = 0;

    mapping(uint256 => address) private collectibles;
    address immutable beacon;

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function buildCollectible(
        string memory __name,
        string memory __symbol,
        string memory __contractURI,
        address __admin,
        uint256 collectibleId,
        address collectibleOwner
    ) public onlyOwner {
        require(
            collectibles[collectibleId] == address(0),
            "UVCollectibleFactory: invalid collectibleId"
        );

        BeaconProxy newCollectibleProxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                UVCollectible(address(0)).initialize.selector,
                __name,
                __symbol,
                __contractURI,
                __admin
            )
        );
        collectibles[collectibleId] = address(newCollectibleProxy);

        // transfer ownership
        UVCollectible(address(newCollectibleProxy)).transferOwnership(
            collectibleOwner
        );
    }

    function getCollectibleAddress(uint256 collectibleId)
        external
        view
        returns (address)
    {
        return collectibles[collectibleId];
    }

    function getBeacon() external view returns (address) {
        return address(beacon);
    }

    function getImplementation() external view returns (address) {
        return UVCollectibleBeacon(beacon).implementation();
    }
}
