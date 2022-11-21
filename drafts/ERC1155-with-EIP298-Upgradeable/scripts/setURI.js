require("dotenv").config();
require("@nomiclabs/hardhat-ethers");

const contract = require("../artifacts/contracts/OctiToken1155Upgradeable.sol/OctiToken1155Upgradeable.json");

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

const setURI = () => {
  const newURI = "https://imx-metadata-test.herokuapp.com/polygon/1155/{id}" 
  console.log("Setting contract URI to", newURI)
  console.log("Waiting 1 block(s) for confirmation...");
   nft
   .setURI(newURI)
   .then((tx) => tx.wait(1))
   .then((receipt) => console.log(`Your transaction is confirmed, its receipt is: ${receipt.transactionHash}`))
   .catch((e) => console.log("something went wrong", e));
};

setURI();

// npx hardhat run scripts/setURI.js --network mumbai

