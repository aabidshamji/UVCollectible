const { ethers, upgrades, run } = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("UVCollectable");

    const contract = await upgrades.deployProxy(factory, [
        "CRT1",
        "Creator 1 x Ultraviolet"
    ], {
        kind: 'uups',
        initializer: "initialize"
    })
    console.log("Deplying transaction and waiting 6 blocks...")
    await contract.deployTransaction.wait(6)
    console.log("NFT deployed to:", contract.address);

    // This solves the bug in Mumbai network where the contract address is not the real one
    const txHash = contract.deployTransaction.hash
    const txReceipt = await ethers.provider.waitForTransaction(txHash)
    const contractAddress = txReceipt.contractAddress
    console.log("CONFIRMED: NFT deployed to", contractAddress)

    const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contractAddress);
    console.log("Implemetation address:", currentImplAddress)

    await run(`verify:verify`, {
        address: contractAddress,
    });
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/deploy.js --network mumbai
// npx hardhat verify --network mumbai PROXY_ADDRESS