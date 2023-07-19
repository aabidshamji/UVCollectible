# UVCollectible Smart Contract

The UVCollectible contract is an ERC721 token contract with enhanced features and functionalities. It allows for the minting, transfer, locking, unlocking, and management of tokens.

## Features

- Token Locking: The contract allows for the locking and unlocking of tokens. Tokens can be locked by the owner or an approved operator. Locked tokens cannot be transferred until they are unlocked.
- Admin Access Control: The contract provides an admin role with additional privileges. The owner and admins can perform certain restricted operations.
- Subscription Management: The contract supports subscriptions for tokens. Tokens can have an expiration timestamp, and the contract provides functions for renewing and canceling subscriptions.
- Minting Tokens: The contract allows the minting of new tokens. Tokens can be minted individually or in bulk for a collection.
- Royalty Information: The contract implements the IERC2981 royalty standard, allowing for the definition of royalty information for tokens and collections. It supports both a default royalty for all tokens and specific royalties for individual collections.
- Metadata and URI: The contract provides functions for updating token and contract metadata, such as name, symbol, and contract URI. It also generates token URIs based on the collection and token IDs.
- Pause Functionality: The contract supports pausing and unpausing token transfers, which can be useful for emergencies or evaluation periods.
- Operator Filter Registry: The contract integrates with the Operator Filter Registry, allowing for operator approvals and transfers to be filtered based on predefined criteria.

## Getting Started

### Prerequisites

- Solidity development environment
- OpenZeppelin library

### Usage

To use the UVCollectible contract in your project, follow these steps:

1. Import the contract into your Solidity code:

```solidity
import "./UVCollectible.sol";
```

2. Create an instance of the UVCollectible contract:

```solidity
UVCollectible uvCollectible = new UVCollectible();
```

3. Use the available functions to interact with the contract and manage tokens.

### Testing

The UVCollectible contract can be tested using Foundry, a smart contract testing framework. Follow these steps to run the tests using Foundry:

1. Install Foundry globally:

```bash
npm install -g foundry-cli
```

2. Navigate to the project directory:

```bash
cd UVCollectible
```

3. Start the local blockchain network using Ganache:

```bash
foundry chain
```

4. In a separate terminal window, deploy the UVCollectible contract to the local network:

```bash
foundry deploy UVCollectible
```

5. Run the tests:

```bash
foundry test
```

The tests are located in the `test` directory and cover various contract functionalities.

## Contributing

Contributions to the UVCollectible project are welcome. If you encounter any issues or have suggestions for improvements, please open an issue or submit a pull request.
