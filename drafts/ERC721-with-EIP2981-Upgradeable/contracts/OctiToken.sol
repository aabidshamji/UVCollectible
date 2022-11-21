// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

/// @custom:security-contact security@octi.com
contract OctiToken is
    Initializable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    string public contractURI;

    // /**
    // * @dev Contract constructor.
    // * @param newOwner Fireblocks account address (to be set as owner).
    // * @param royaltyAddress Address to send contract-level royalties.
    // * @param _newContractURI String representing RFC 3986 URI.
    // */
    // constructor(
    //     address newOwner,
    //     address royaltyAddress,
    //     string memory _newContractURI
    // ) ERC721("Ultraviolet", "OCTI") {
    //     // Fees are in basis points (x/10000)
    //     updateDefaultRoyalty(royaltyAddress, 1000);
    //     updateContractURI(_newContractURI);
    //     transferOwnership(newOwner);
    // }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address royaltyAddress, string memory _newContractURI)
        public
        initializer
    {
        __ERC721_init("Ultraviolet", "OCTI");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();

        updateDefaultRoyalty(royaltyAddress, 1000);
        updateContractURI(_newContractURI);
    }

    /// UUPS module required by openZ — Stops unauthorized upgrades
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev Get the current base URI.
     * @notice This is an internal function used to generate the URI for the token.
     */
    function _baseURI() internal view override returns (string memory) {
        return contractURI;
    }

    /**
     * @dev Changes the base URI
     * @param _newContractURI String representing RFC 3986 URI.
     */
    function updateContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
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
     * @param feeReceiver Address to receive the royalties. Cannot be the zero address.
     * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
     */
    function safeMintWithRoyalty(
        address to,
        uint256 tokenId,
        address feeReceiver,
        uint96 feeNumerator
    ) public onlyOwner {
        safeMint(to, tokenId);
        updateTokenRoyalty(tokenId, feeReceiver, feeNumerator);
    }

    /**
     * @dev Implements pause functionality.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Royalties
    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     * @param receiver Address to receive the royalties. Cannot be the zero address.
     * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * @param receiver Address to receive the royalties. Cannot be the zero address.
     * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
     */
    function updateTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
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
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
