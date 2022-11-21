// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @custom:security-contact security@ultraviolet.club
contract OctiTokenCollectable is
    Initializable,
    ERC721Upgradeable,
    IERC2981Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /**
     * @dev Emmited when token is created
     */
    event Minted(uint256 indexed eventId, uint256 tokenId, address owner);

    /**
     * @dev Emmited when token is frozen
     */
    event Frozen(uint256 tokenId);

    /**
     * @dev Emmited when token is unfrozen by function call
     */
    event Unfrozen(uint256 tokenId);

    // Stores the base contractURI
    string public contractURI;

    // Last Used id (used to generate new ids)
    uint256 public lastId;

    // Event Id for each token
    mapping(uint256 => uint256) private _tokenEvent;

    // Frozen tokens
    mapping(uint256 => bool) private _tokenFrozen;

    // ERC2981 Royalty Info
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _eventRoyaltyInfo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address __royaltyAddress, string memory __contractURI)
        public
        initializer
    {
        __ERC721_init("Ultraviolet Collectable", "ULTRAC");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        updateDefaultRoyalty(__royaltyAddress, 1000);
        updateContractURI(__contractURI);
    }

    /// UUPS module required by openZ — Stops unauthorized upgrades
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev Gets URI for the token metadata
     * @param tokenId ( uint256 ) The Token Id you want to get the URI
     * @return ( string ) URI for the token metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        uint256 eventId = _tokenEvent[tokenId];

        return
            string(
                abi.encodePacked(
                    contractURI,
                    StringsUpgradeable.toString(eventId),
                    "/",
                    StringsUpgradeable.toString(tokenId)
                )
            );
    }

    /**
     * @dev Gets URI for the token metadata
     * @param eventId ( uint256 ) The Event Id you want to get the URI
     * @return ( string ) URI for the event metadata
     */
    function eventURI(uint256 eventId)
        public
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    contractURI,
                    StringsUpgradeable.toString(eventId)
                )
            );
    }

    /**
     * @dev Changes the base URI
     * @param __contractURI String representing RFC 3986 URI.
     */
    function updateContractURI(string memory __contractURI) public onlyOwner {
        contractURI = __contractURI;
    }

    /**
     * @dev Sets Last Id for minting.
     * Requires
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param newLastId ( uint256 ) The new Last Id
     
     */
    function setLastId(uint256 newLastId) public onlyOwner whenNotPaused {
        require(lastId < newLastId, "New Id has to be higher");
        lastId = newLastId;
    }

    /**
     * @dev Gets the Event Id for the token
     * @param tokenId ( uint256 ) The Token Id you want to query
     * @return ( uint256 ) representing the Event id for the token
     */
    function tokenEvent(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        return _tokenEvent[tokenId];
    }

    /**
     * @dev Gets the Token Id and Event Id for a given index of the tokens list of the requested owner
     * @param owner ( address ) Owner address of the token list to be queried
     * @param index ( uint256 ) Index to be accessed of the requested tokens list
     * @return tokenId ( uint256 ) Token Id for the given index of the tokens list owned by the requested address
     * @return eventId ( uint256 ) Event Id for the given token
     */
    function tokenDetailsOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId, uint256 eventId)
    {
        tokenId = tokenOfOwnerByIndex(owner, index);
        eventId = tokenEvent(tokenId);
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

    // Freezing
    /**
     * @dev Gets the token freeze status
     * @param tokenId ( uint256 ) The token id to check.
     * @return bool representing the token freeze status
     */
    function isFrozen(uint256 tokenId) public view returns (bool) {
        return _tokenFrozen[tokenId];
    }

    /**
     * @dev Modifier to make a function callable only when the toke is not frozen.
     * @param tokenId ( uint256 ) The token id to check.
     */
    modifier whenNotFrozen(uint256 tokenId) {
        require(!this.isFrozen(tokenId), "Token is frozen");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the token is frozen.
     * @param tokenId ( uint256 ) The token id to check.
     */
    modifier whenFrozen(uint256 tokenId) {
        require(this.isFrozen(tokenId), "Token is not frozen");
        _;
    }

    /**
     * @dev Freeze a specific ERC721 token.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * - The token does not have to be frozen
     * @param tokenId ( uint256 ) Id of the ERC721 token to be frozen.
     */
    function freeze(uint256 tokenId)
        public
        onlyOwner
        whenNotPaused
        whenNotFrozen(tokenId)
    {
        _freeze(tokenId);
    }

    /**
     * @dev Unfreeze a specific ERC721 token.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * - The token must be frozen
     * @param tokenId ( uint256 ) Id of the ERC721 token to be unfrozen.
     */
    function unfreeze(uint256 tokenId)
        public
        onlyOwner
        whenNotPaused
        whenFrozen(tokenId)
    {
        _unfreeze(tokenId);
    }

    /**
     * @dev Internal function to freeze a specific token
     * @param tokenId ( uint256 ) Id of the token being frozen by the _msgSender
     */
    function _freeze(uint256 tokenId) internal {
        _tokenFrozen[tokenId] = true;
        emit Frozen(tokenId);
    }

    /**
     * @dev Internal function to freeze a specific token
     * @param tokenId ( uint256 ) Id of the token being frozen by the _msgSender
     */
    function _unfreeze(uint256 tokenId) internal {
        delete _tokenFrozen[tokenId];
        emit Unfrozen(tokenId);
    }

    // Reclaim Tokens
    /**
     * @dev Reclaim a token from a user to the owner's wallet
     * Requires:
     *  - msg sender to be the contract owner
     * @param tokenId ( uint256 ) Id of the token being reclaimed
     */
    function reclaimToken(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "ERC721: token does not exist");
        _transfer(ownerOf(tokenId), owner(), tokenId);
        if (isFrozen(tokenId)) {
            _unfreeze(tokenId);
        }
    }

    // Minting
    /**
     * @dev Mint token to address.
     * Requires
     * - The msg sender to be the onwer
     * - The contract does not have to be paused
     * @param eventId ( uint256 ) EventId for the new token
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(uint256 eventId, address to)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        // Updates Last Id first to not overlap
        lastId += 1;
        return _mintToken(eventId, lastId, to);
    }

    /**
     * @dev Mint token to many addresses.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * @param eventId ( uint256 ) EventId for the new token
     * @param to ( array of address ) The addresses that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(uint256 eventId, address[] memory to)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        // First mint all tokens
        for (uint256 i = 0; i < to.length; ++i) {
            _mintToken(eventId, lastId + 1 + i, to[i]);
        }
        // Last update Last Id with the Events Id
        lastId += to.length;
        return true;
    }

    /**
     * @dev Mint many tokens to address.
     * Requires
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param eventIds ( array uint256 ) Event Ids to assing to user
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(uint256[] memory eventIds, address to)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        // First mint all tokens
        for (uint256 i = 0; i < eventIds.length; ++i) {
            _mintToken(eventIds[i], lastId + 1 + i, to);
        }
        // Last update Last Id with the Events Id
        lastId += eventIds.length;
        return true;
    }

    /**
     * @dev Internal function to mint tokens
     * @param eventId ( uint256 ) EventId for the new token
     * @param tokenId ( uint256 ) The token id to mint. Minted by message.sender
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 eventId,
        uint256 tokenId,
        address to
    ) internal returns (bool) {
        _safeMint(to, tokenId);
        _tokenEvent[tokenId] = eventId;
        emit Minted(eventId, tokenId, to);
        return true;
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
        whenNotFrozen(tokenId)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Royalties
    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 _eventId = tokenEvent(_tokenId);

        RoyaltyInfo memory royalty = _eventRoyaltyInfo[_eventId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

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
     * @dev Removes default royalty information.
     */
    function removeDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * @param receiver Address to receive the royalties. Cannot be the zero address.
     * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
     */
    function updateEventRoyalty(
        uint256 eventId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setEventRoyalty(eventId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function removeEventRoyalty(uint256 eventId) public onlyOwner {
        _resetEventRoyalty(eventId);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
        virtual
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setEventRoyalty(
        uint256 eventId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _eventRoyaltyInfo[eventId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetEventRoyalty(uint256 eventId) internal virtual {
        delete _eventRoyaltyInfo[eventId];
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenEvent[tokenId];
        delete _tokenFrozen[tokenId];
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
