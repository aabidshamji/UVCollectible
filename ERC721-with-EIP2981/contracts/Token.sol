// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OctiToken is 
    ERC721, 
    ERC2981, 
    ERC721Enumerable, 
    Pausable, 
    Ownable, 
    ERC721Burnable 
{

    string private _contractURI;
    
    /**
    * @dev Contract constructor.
    * @param newOwner Fireblocks account address (to be set as owner).
    * @param royaltyAddress Address to send contract-level royalties.
    * @param _newContractURI String representing RFC 3986 URI.
    */
    constructor(
        address newOwner, 
        address royaltyAddress, 
        string memory _newContractURI
    ) ERC721("Ultraviolet", "OCTI") {
        transferOwnership(newOwner);
        // Fees are in basis points (x/10000)
        updateDefaultRoyalty(royaltyAddress, 1000);
        updateBaseURI(_newContractURI);
    }

    string private baseURI = "https://testnets.ultraviolet.world/polygon/";

    /**
    * @dev Get the current base URI.
    * @notice This is an internal function used to generate the URI for the token.
    */
    function _baseURI() internal view override returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev Changes the base URI 
    * @param _newContractURI String representing RFC 3986 URI.
    */
    function updateBaseURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
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

    // Minting
    /**
    * @dev Mints a new NFT.
    * @param to The address that will own the minted NFT.
    * @param tokenId of the NFT to be minted by the msg.sender.
    */
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    /**
    * @dev Mints a new NFT.
    * @notice Used to mint a token and set token-level royalties in one contract call 
    * @param to The address that will own the minted NFT.
    * @param tokenId of the NFT to be minted by the msg.sender.
    * @param receiver Address to receive the royalties. Cannot be the zero address.
    * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
    */
    function mintNFTWithRoyalty(
        address to, 
        uint256 tokenId, 
        address receiver, 
        uint96 feeNumerator
    ) public onlyOwner {
        safeMint(to, tokenId);
        updateTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
    * @dev Implements pause functionality.
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev Override isApprovedForAll to auto-approve OpenSea's proxy contract
    * @notice Typically, you (a seller) would have to call your smart contract's setApprovalForAll() 
    * method with OpenSea's address to approve it as an operator, which would cost you gas.
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override(ERC721, IERC721) 
        view 
        returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
      // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
      // for Polygon's mainnet, use 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
        if (_operator == address(0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}