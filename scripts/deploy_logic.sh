#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi


forge create ./src/UVCollectible.sol:UVCollectible -i \
  --rpc-url ${RPC_URL}${ALCHEMY_API_KEY} \
  --private-key ${PRIVATE_KEY} \
  --verify \
  --etherscan-api-key ${POLYGONSCAN_API_KEY} 