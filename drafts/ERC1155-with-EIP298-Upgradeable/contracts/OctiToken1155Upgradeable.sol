// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract OctiToken1155Upgradeable is
    Initializable, 
    OwnableUpgradeable, 
    ERC1155Upgradeable, 
    ERC2981Upgradeable, 
    ERC1155SupplyUpgradeable, 
    ERC1155PausableUpgradeable, 
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable 
{   
    
    string public name;
    string public symbol;
    string private _contractURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {

        name = "Ultraviolet";
        symbol = "UV";
        _contractURI = "https://imx-metadata-test.herokuapp.com/polygon/";

        __ERC1155_init("https://imx-metadata-test.herokuapp.com/polygon/{id}");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
    }

    /**
    * @dev Changes the base URI 
    * @param newuri String representing RFC 3986 URI.
    */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
    * @dev Changes the contract URI 
    * @param newuri String representing RFC 3986 URI.
    */
    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }

    /**
    * @dev Contract-level metadata for OpenSea
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Pause
    /**
    * @dev Freezes all token transfers.
    * @notice Useful for scenarios such as preventing trades until the end of an evaluation period, 
    * or having an emergency switch for freezing all token transfers in the event of a large bug.
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @dev Removes a pause.
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @dev Supports Pausable functionality.
    */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Minting
    /**
    * @dev Mints a new NFT.
    * @param account The address that will own the minted NFT.
    * @param id of the NFT to be minted by the msg.sender.
    * @param amount number of tokens to mint to that address
    * @param data Additional data with no specified format, sent unaltered in call to `onERC1155Received` on `_to`
    */
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    /**
    * @dev Mints multiple tokens to a single recipient.
    * @param to The address that will own the minted NFTs.
    * @param ids An array of IDs for the NFTs to be minted.
    * @param amounts An array of the quantities of NFTs to be minted to account
    * @param data Additional data with no specified format, sent unaltered in call to `onERC1155Received` on `_to`
    */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // Royalties
    /**
    * @dev Sets the royalty information that all ids in this contract will default to.
    * @param receiver Address to receive the royalties. Cannot be the zero address.
    * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
    */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
    * @dev Sets the royalty information for a specific token id, overriding the global default.
    * @param receiver Address to receive the royalties. Cannot be the zero address.
    * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
    */
    function updateTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
    * @dev Resets royalty information for the token id back to the global default.
    */
    function removeTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
    * @dev Removes default royalty information.
    */
    function removeDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// Upgradability
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /// Derived contract must override function "supportsInterface"
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}
