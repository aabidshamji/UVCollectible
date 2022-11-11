const { ethers, upgrades } = require("hardhat");

async function main() {
    const contractName = 'UVCollectable'
    const factory = await hre.ethers.getContractFactory(contractName);

    const deployData = factory.getDeployTransaction()

    const estimatedGas = await hre.ethers.estimatedGas(deployData)

    console.log(`Estimated Gas for ${contractName}:`, estimatedGas)
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/estiamteGas.js --network mumbai
