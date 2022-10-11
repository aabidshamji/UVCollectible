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

/// @custom:security-contact security@octi.com
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
    event EventToken(uint256 indexed eventId, uint256 tokenId, address owner);

    // Stores the base contractURI
    string public _contractURI;

    // Last Used id (used to generate new ids)
    uint256 public lastId;

    // Event Id for each token
    mapping(uint256 => uint256) private _tokenEvent;

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
        __ERC721_init("Ultraviolet", "OCTI");
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
        _requireMinted(tokenId);
        uint256 eventId = _tokenEvent[tokenId];
        return
            _strConcat(
                _contractURI,
                _uint2str(eventId),
                "/",
                _uint2str(tokenId),
                ""
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
        return _strConcat(_contractURI, _uint2str(eventId), "", "", "");
    }

    /**
     * @dev Changes the base URI
     * @param __contractURI String representing RFC 3986 URI.
     */
    function updateContractURI(string memory __contractURI) public onlyOwner {
        _contractURI = __contractURI;
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
        emit EventToken(eventId, tokenId, to);
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
    function removeEventRoyalty(uint256 tokenId) public onlyOwner {
        _resetEventRoyalty(tokenId);
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
    function _resetEventRoyalty(uint256 tokenId) internal virtual {
        delete _eventRoyaltyInfo[tokenId];
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenEvent[tokenId];
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

    // Helper Functions
    /**
     * @dev Function to convert uint to string
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Function to concat strings
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
}
