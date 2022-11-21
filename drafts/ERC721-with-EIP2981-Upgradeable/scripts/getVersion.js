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
   const version = await nft.getVersion();
   console.log(version)
};

mintToken();

// npx hardhat run scripts/getVersion.js --network mumbai
