const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UVCollectable", function () {
    it("Deployment", async function () {
        const factory = await ethers.getContractFactory("UVCollectable");
        const contract = await upgrades.deployProxy(factory, [
            "CRT1",
            "Creator 1 x Ultraviolet"
        ], {
            kind: 'uups',
            initializer: "initialize"
        })
        await contract.deployed()
    });
});