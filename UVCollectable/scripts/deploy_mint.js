const { ethers, upgrades, run } = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("UVCollectable");

    const contract = await upgrades.deployProxy(factory, [
        "CRT1",
        "Creator 1 x Ultraviolet",
        "token.ultraviolet.club/collectables/creatorusername1/",
        ["0x9367Ee417ae552cb94f3249d0424000747877AA8"]
    ], {
        kind: 'uups',
        initializer: "initialize"
    })
    console.log("Deplying transaction and waiting 6 blocks...")
    await contract.deployTransaction.wait(6)
    console.log("NFT deployed to:", contract.address);

    console.log("Minting token...");

    const to = "0x9367Ee417ae552cb94f3249d0424000747877AA8"
    const eventId = "10"
    await contract
        .mintToken(eventId, to, false, 0)
        .then((tx) => tx.wait(6))
        .then((receipt) => console.log(`Your transaction is confirmed, its receipt is: ${receipt.transactionHash}`))
        .catch((e) => console.log("something went wrong", e));

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

// npx hardhat run scripts/deploy_mint.js --network mumbai
// npx hardhat verify --network mumbai PROXY_ADDRESS