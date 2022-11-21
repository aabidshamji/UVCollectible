// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract OctiToken1155 is 
    Ownable, 
    ERC1155, 
    ERC2981, 
    ERC1155Supply, 
    ERC1155Pausable, 
    ERC1155Burnable 
{    
    /**
    * @dev Contract constructor.
    */
    constructor() ERC1155("https://testnets.ultraviolet.world/metadata/polygon/") { }

    /**
    * @dev Changes the base URI 
    * @param newuri String representing RFC 3986 URI.
    */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
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
        override(ERC1155, ERC1155Supply, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Minting
    /**
    * @dev Mints a new NFT.
    * @param to The address that will own the minted NFT.
    * @param id of the NFT to be minted by the msg.sender.
    * @param amount number of tokens to mint to that address
    * @param data Additional data with no specified format, sent unaltered in call to `onERC1155Received` on `_to`
    */
    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(to, id, amount, data);
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

    /// Derived contract must override function "supportsInterface".
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}