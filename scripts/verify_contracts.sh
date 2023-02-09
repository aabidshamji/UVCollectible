#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

# logic
forge verify-contract ${LOGIC_ADDRESS} src/UVCollectible.sol:UVCollectible \
    --compiler-version v0.8.12 \
    --num-of-optimizations 200 \
    ${POLYGONSCAN_API_KEY} \
    --chain-id ${CHAIN_ID} \
    --watch

# # beacon
# forge verify-contract ${BEACON_ADDRESS} src/UVCollectibleBeacon.sol:UVCollectibleBeacon \ 
#     --compiler-version v0.8.12 \
#     --num-of-optimizations 200 \
#     ${POLYGONSCAN_API_KEY} \
#     --constructor-args- ${LOGIC_ADDRESS} \
#     --chain-id ${CHAIN_ID} \
#     --watch

# # factory
# forge verify-contract ${FACTORY_ADDRESS} src/UVCollectibleFactory.sol:UVCollectibleFactory \
#     --compiler-version v0.8.12 \
#     --num-of-optimizations 200 \
#     ${POLYGONSCAN_API_KEY} \
#     --constructor-args- ${BEACON_ADDRESS} \
#     --chain-id ${CHAIN_ID} \
#     --watch
