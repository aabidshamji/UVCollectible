require('dotenv').config();
const { ethers, upgrades } = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("OctiTokenV2");

    const proxyAddress = process.env.PROXY_CONTRACT

    const nftUpgraded = await upgrades.upgradeProxy(process.env.PROXY_CONTRACT, factory);

    console.log("Upgrade Implementation address:", nftUpgraded);

//     await contract.deployed();
//     console.log("NFT deployed to:", contract.address);

//     // This solves the bug in Mumbai network where the contract address is not the real one
//     const txHash = contract.deployTransaction.hash
//     const txReceipt = await ethers.provider.waitForTransaction(txHash)
//     const contractAddress = txReceipt.contractAddress
//     console.log("CONFIRMED: NFT deployed to", contractAddress)
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/upgrade.js --network mumbai
