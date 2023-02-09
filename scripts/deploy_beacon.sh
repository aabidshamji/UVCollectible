#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

echo "Please enter the blueprint/logic contract address..."
read logic
echo "Deploying beacon for the implementation $logic..."

forge create ./src/UVCollectibleBeacon.sol:UVCollectibleBeacon -i \
  --rpc-url ${RPC_URL}${ALCHEMY_API_KEY} \
  --private-key ${PRIVATE_KEY} \
  --constructor-args $logic \
  --verify \
  --etherscan-api-key ${POLYGONSCAN_API_KEY} 