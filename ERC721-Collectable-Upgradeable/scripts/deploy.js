const { ethers, upgrades } = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("OctiTokenCollectable");

    const contract = await upgrades.deployProxy(factory, [
        "0xdF81E19912896af20fF1be1c1Bb4487f6Ff423E0",
        "https://testnets.ultraviolet.world/metadata/polygon/"
    ], {
        kind: 'uups',
        initializer: "initialize"
    })

    await contract.deployed();
    console.log("NFT deployed to:", contract.address);

    // This solves the bug in Mumbai network where the contract address is not the real one
    const txHash = contract.deployTransaction.hash
    const txReceipt = await ethers.provider.waitForTransaction(txHash)
    const contractAddress = txReceipt.contractAddress
    console.log("CONFIRMED: NFT deployed to", contractAddress)
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/deploy.js --network mumbai
