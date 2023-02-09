#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

echo "Please enter the beacon address..."
read beacon
echo "Deploying factory for beacon $beacon..."

forge create ./src/UVCollectibleFactory.sol:UVCollectibleFactory -i \
    --rpc-url ${RPC_URL}${ALCHEMY_API_KEY} \
    --private-key ${PRIVATE_KEY} \
    --constructor-args $beacon \
    --verify \
    --etherscan-api-key ${POLYGONSCAN_API_KEY} 