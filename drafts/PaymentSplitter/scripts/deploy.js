const hre = require("hardhat");

async function main() {
    const NFT = await hre.ethers.getContractFactory("PaymentSplitter");
    const nft = await NFT.deploy(
        ["0xd8da6bf26964af9d7eed9e03e53415d37aa96045", "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"],
        [10, 5]
    );
    await nft.deployed();
    console.log("NFT deployed to:", nft.address);
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});