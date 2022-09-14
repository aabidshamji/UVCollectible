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

const mintToken = () => {
  const account = wallet.address // "0x9367Ee417ae552cb94f3249d0424000747877AA8"
  const tokenId = "400"
  const amount = "10"
  const data = []
  console.log(`Minting Token: account=${account} tokenId=${tokenId} amount=${amount} data=${data}`)
  console.log("Waiting 1 block(s) for confirmation...");
   nft
   .mint(account, tokenId, amount, data)
   .then((tx) => tx.wait(1))
   .then((receipt) => console.log(`Your transaction is confirmed, its receipt is: ${receipt.transactionHash}`))
   .catch((e) => console.log("something went wrong", e));
};

mintToken();

// npx hardhat run scripts/mint.js --network mumbai

