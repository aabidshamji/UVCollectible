const hre = require("hardhat");

async function main() {
    const NFT = await hre.ethers.getContractFactory("OctiToken");
    const nft = await NFT.deploy(
        "0x9367Ee417ae552cb94f3249d0424000747877AA8",
        "0xdF81E19912896af20fF1be1c1Bb4487f6Ff423E0",
        "https://testnets.ultraviolet.world/metadata/polygon/"
    );
    await nft.deployed();
    console.log("NFT deployed to:", nft.address);

    // This solves the bug in Mumbai network where the contract address is not the real one
    const txHash = nft.deployTransaction.hash
    const txReceipt = await ethers.provider.waitForTransaction(txHash)
    const contractAddress = txReceipt.contractAddress
    console.log("CONFIRMED: NFT deployed to", contractAddress)
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/deploy.js --network mumbai
// solc --standard-json  -o ./ OctiToken.sol