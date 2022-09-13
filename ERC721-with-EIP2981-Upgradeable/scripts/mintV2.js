require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
const { v4: uuidv4 } = require('uuid');
const uuidToHex = require('uuid-to-hex');

const contract = require("../artifacts/contracts/OctiToken.sol/OctiToken.json");
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
   const tokenId = uuidToHex(uuidv4(), true)
   console.log(`NFT ${tokenId} minting to: ${wallet.address}`)
   console.log("Waiting 1 block(s) for confirmation...");
   nft
   // .safeMint("0x9367Ee417ae552cb94f3249d0424000747877AA8", '0')
      .safeMint(wallet.address, tokenId)
      .then((tx) => tx.wait(1))
      .then((receipt) => console.log(`Your transaction is confirmed, its receipt is: ${receipt.transactionHash}`))

      .catch((e) => console.log("something went wrong", e));
};

mintToken();

// npx hardhat run scripts/mintV2.js --network mumbai
