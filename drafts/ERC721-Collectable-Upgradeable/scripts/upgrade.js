require('dotenv').config();
const { ethers, upgrades } = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("OctiTokenCollectableNew");

    const proxyAddress = process.env.PROXY_CONTRACT

    const nftUpgraded = await upgrades.upgradeProxy(process.env.PROXY_CONTRACT, factory);

    console.log("Upgraded Implementation address:", nftUpgraded.deployTransaction.to);

    await nftUpgraded.deployed();
    console.log("NFT deployed to:", nftUpgraded.address);

}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/upgrade.js --network mumbai
