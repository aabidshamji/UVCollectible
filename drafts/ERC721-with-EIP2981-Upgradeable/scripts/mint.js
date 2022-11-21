require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
const { v4: uuidv4 } = require('uuid');
const uuidToHex = require('uuid-to-hex');

async function mintNFT() {
   const ExampleNFT = await ethers.getContractFactory("OctiToken")
   const [owner] = await ethers.getSigners()
   const tokenId = uuidToHex(uuidv4(), true)

   await ExampleNFT.attach(process.env.PROXY_CONTRACT).safeMint(owner.address, tokenId)
   
   console.log(`NFT ${tokenId} minted to: ${owner.address}`)
}

mintNFT()

// npx hardhat run scripts/mint.js --network mumbai