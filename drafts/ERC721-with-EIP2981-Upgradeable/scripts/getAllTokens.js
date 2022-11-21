require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
const { v4: uuidv4 } = require('uuid');
const uuidToHex = require('uuid-to-hex');

const contract = require("../artifacts/contracts/OctiTokenV2.sol/OctiTokenV2.json");
const contractInterface = contract.abi;

// https://hardhat.org/plugins/nomiclabs-hardhat-ethers.html#provider-object
let provider = ethers.provider;

const privateKey = `0x${process.env.PRIVATE_KEY}`;
const wallet = new ethers.Wallet(privateKey);

wallet.provider = provider;
const signer = wallet.connect(provider);

// https://docs.ethers.io/v5/api/contract/contract
const nft = new ethers.Contract(
  process.env.PROXY_CONTRACT,
  contractInterface,
  signer
);

async function mintToken() {
   const totalSupply = await nft.totalSupply();
   for (let i = 0; i < totalSupply.toNumber(); i++) {
    const token = await nft.tokenByIndex(String(i));
    const tokenId = parseInt(token, 16)
    const owner = await nft.ownerOf(token);
    console.log(`${i}: ${tokenId} (${token}) -> ${owner}`);
   }
};

mintToken();

// npx hardhat run scripts/getAllTokens.js --network mumbai
