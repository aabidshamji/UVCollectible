const hre = require("hardhat");

async function main() {
    const NFT = await hre.ethers.getContractFactory("Token");
    const nft = await NFT.deploy(
        "0xd8da6bf26964af9d7eed9e03e53415d37aa96045",
        "https://testnets.ultraviolet.world/metadata/polygon/"
    );
    await nft.deployed();
    console.log("NFT deployed to:", nft.address);
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});