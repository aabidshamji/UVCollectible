// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "./IERC5643.sol";

/// @custom:security-contact security@ultraviolet.club
contract UVCollectable is
    Initializable,
    ERC721Upgradeable,
    IERC2981Upgradeable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IERC5643,
    ERC2771Recipient
{
    /************************************************************************************************
     * Events
     ************************************************************************************************/

    /**
     * @dev Emmited when token is frozen
     */
    event Frozen(uint256 tokenId);

    /**
     * @dev Emmited when token is unfrozen by function call
     */
    event Unfrozen(uint256 tokenId);

    /**
     * @dev Emmited when an admin is added or removed
     */
    event AdminUpdated(address admin, bool added);

    /************************************************************************************************
     * Variables
     ************************************************************************************************/
    // Stores the base contractURI
    string public contractURI;

    // Last Used id (used to generate new ids)
    uint256 public lastId;

    // Collection Id for each token
    mapping(uint256 => uint256) private _tokenCollection;

    // Frozen tokens
    mapping(uint256 => bool) private _tokenFrozen;

    // ERC2981 Royalty Info
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }
    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _collectionRoyaltyInfo;

    // Subscription Info
    mapping(uint256 => uint64) private _expirations;

    // Admin Info
    mapping(address => bool) private _admins;

    /************************************************************************************************
     * Initialization
     ************************************************************************************************/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory __name, string memory __symbol)
        public
        initializer
    {
        __ERC721_init(__name, __symbol);
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        address uvAdmin = 0x9367Ee417ae552cb94f3249d0424000747877AA8;
        _admins[uvAdmin] = true;
        emit AdminUpdated(uvAdmin, true);
    }

    /************************************************************************************************
     * Metatranscations
     ************************************************************************************************/
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771Recipient)
        returns (address)
    {
        return ERC2771Recipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771Recipient)
        returns (bytes memory)
    {
        return ERC2771Recipient._msgData();
    }

    /************************************************************************************************
     * Admin Access Control
     ************************************************************************************************/
    /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() || isAdmin(_msgSender()),
            "caller is not owner or admin"
        );
        _;
    }

    /**
     * @dev Returns the true if the address is an admin user, else false.
     * @param user ( address )
     */
    function isAdmin(address user) public view returns (bool) {
        return _admins[user];
    }

    /**
     * @dev Grants admin user privilages to newAdmin.
     * @param newAdmin ( address )
     */
    function addAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        _admins[newAdmin] = true;
        emit AdminUpdated(newAdmin, true);
    }

    /**
     * @dev Revokes admin user privilages to admin.
     * @param admin ( address )
     */
    function removeAdmin(address admin) external virtual onlyOwnerOrAdmin {
        delete _admins[admin];
        emit AdminUpdated(admin, false);
    }

    /************************************************************************************************
     * Upgradability
     ************************************************************************************************/
    /// UUPS module required by openZ — Stops unauthorized upgrades
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwnerOrAdmin
    {}

    /************************************************************************************************
     * Metadata
     ************************************************************************************************/
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
        uint256 collectionId = _tokenCollection[tokenId];

        return
            string(
                abi.encodePacked(
                    contractURI,
                    StringsUpgradeable.toString(collectionId),
                    "/",
                    StringsUpgradeable.toString(tokenId)
                )
            );
    }

    /**
     * @dev Gets URI for the token metadata
     * @param collectionId ( uint256 ) The collection id you want to get the URI
     * @return ( string ) URI for the collection metadata
     */
    function collectionURI(uint256 collectionId)
        public
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    contractURI,
                    StringsUpgradeable.toString(collectionId)
                )
            );
    }

    /**
     * @dev Changes the base URI
     * @param __contractURI String representing RFC 3986 URI.
     */
    function updateContractURI(string memory __contractURI)
        public
        onlyOwnerOrAdmin
    {
        contractURI = __contractURI;
    }

    /**
     * @dev Sets Last Id for minting.
     * Requires
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param newLastId ( uint256 ) The new Last Id
     
     */
    function setLastId(uint256 newLastId)
        public
        onlyOwnerOrAdmin
        whenNotPaused
    {
        require(lastId < newLastId, "New Id has to be higher");
        lastId = newLastId;
    }

    /************************************************************************************************
     * Enumerable
     ************************************************************************************************/
    /**
     * @dev Gets the collection Id for the token
     * @param tokenId ( uint256 ) The Token Id you want to query
     * @return ( uint256 ) representing the collection id for the token
     */
    function tokenCollection(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        return _tokenCollection[tokenId];
    }

    /************************************************************************************************
     * Pause
     ************************************************************************************************/
    /**
     * @dev Freezes all token transfers.
     * @notice Useful for scenarios such as preventing trades until the end of an evaluation period,
     * or having an emergency switch for freezing all token transfers in the event of a large bug.
     */
    function pause() public onlyOwnerOrAdmin {
        _pause();
    }

    /**
     * @dev Removes a pause.
     */
    function unpause() public onlyOwnerOrAdmin {
        _unpause();
    }

    /************************************************************************************************
     * Freeze
     ************************************************************************************************/
    /**
     * @dev Gets the token freeze status
     * @param tokenId ( uint256 ) The token id to check.
     * @return bool representing the token freeze status
     */
    function isFrozen(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return _tokenFrozen[tokenId];
    }

    /**
     * @dev Modifier to make a function callable only when the toke is not frozen.
     * @param tokenId ( uint256 ) The token id to check.
     */
    modifier whenNotFrozen(uint256 tokenId) {
        require(!isFrozen(tokenId), "Token is frozen");
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
    function freeze(uint256 tokenId) public onlyOwnerOrAdmin whenNotPaused {
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
    function unfreeze(uint256 tokenId) public onlyOwnerOrAdmin whenNotPaused {
        require(isFrozen(tokenId), "Token is not frozen");
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

    /************************************************************************************************
     * Subscriptions
     ************************************************************************************************/
    /**
     * @dev See {IERC5643-renewSubscription}.
     */
    function renewSubscription(uint256 tokenId, uint64 duration)
        external
        virtual
        onlyOwnerOrAdmin
    {
        _requireMinted(tokenId);
        _extendSubscription(tokenId, duration);
    }

    /**
     * @dev Extends the subscription for `tokenId` for `duration` seconds.
     * If the `tokenId` does not exist, an error will be thrown.
     * @param tokenId ( uint256 ) Id of the token
     * @param duration ( uint64 ) duration in seconds to renew the subscription for
     * Emits a {SubscriptionUpdate} event after the subscription is extended.
     */
    function _extendSubscription(uint256 tokenId, uint64 duration)
        internal
        virtual
    {
        uint64 currentExpiration = _expirations[tokenId];
        uint64 newExpiration;
        if (currentExpiration == 0) {
            newExpiration = uint64(block.timestamp) + duration;
        } else {
            newExpiration = currentExpiration + duration;
        }

        _expirations[tokenId] = newExpiration;

        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    /**
     * @dev See {IERC5643-cancelSubscription}.
     */
    function cancelSubscription(uint256 tokenId)
        external
        virtual
        onlyOwnerOrAdmin
    {
        delete _expirations[tokenId];
        emit SubscriptionUpdate(tokenId, 0);
    }

    /**
     * @dev See {IERC5643-expiresAt}.
     */
    function expiresAt(uint256 tokenId) external view virtual returns (uint64) {
        _requireMinted(tokenId);
        return _expirations[tokenId];
    }

    /**
     * @dev See {IERC5643-isRenewable}.
     */
    function isRenewable(
        uint256 /*tokenId*/
    ) external pure returns (bool) {
        return true;
    }

    /**
     * @dev Sets the expiration of the token to the current timestamp
     * @param tokenId ( uint256 ) id for the token
     */
    function expireSubscription(uint256 tokenId)
        external
        virtual
        onlyOwnerOrAdmin
    {
        uint64 currentTime = uint64(block.timestamp);
        require(
            _expirations[tokenId] >= currentTime,
            "Token cannot already be expired"
        );
        _expirations[tokenId] = currentTime;
        emit SubscriptionUpdate(tokenId, currentTime);
    }

    /**
     * @dev Sets the expiration time of the given token
     * If the `tokenId` does not exist, an error will be thrown.
     * @param tokenId ( uint256 ) Id of the token
     * @param newExpiration ( uint64 ) time that the token expires
     * Emits a {SubscriptionUpdate} event after the subscription is modified.
     */
    function setExpiration(uint256 tokenId, uint64 newExpiration)
        public
        onlyOwnerOrAdmin
    {
        _requireMinted(tokenId);
        _expirations[tokenId] = newExpiration;
        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    /************************************************************************************************
     * Reclaim
     ************************************************************************************************/
    /**
     * @dev Reclaim a token from a user to the owner's wallet
     * Requires:
     *  - msg sender to be the contract owner
     * @param tokenId ( uint256 ) Id of the token being reclaimed
     */
    function reclaimToken(uint256 tokenId) public onlyOwnerOrAdmin {
        require(isFrozen(tokenId), "Token must be frozen");
        _unfreeze(tokenId);
        _transfer(ownerOf(tokenId), owner(), tokenId);
    }

    /************************************************************************************************
     * Minting
     ************************************************************************************************/
    /**
     * @dev Mint token to address.
     * Requires
     * - The msg sender to be the onwer
     * - The contract does not have to be paused
     * @param collectionId ( uint256 ) collectionId for the new token
     * @param to ( address ) The address that will receive the minted tokens.
     * @param frozen ( bool ) true if minted token should be frozen, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 collectionId,
        address to,
        bool frozen,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        // Updates Last Id first to not overlap
        lastId += 1;
        return _mintToken(collectionId, lastId, to, frozen, validDuration);
    }

    /**
     * @dev Mint token to many addresses.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * @param collectionId ( uint256 ) collectionId for the new token
     * @param to ( array of address ) The addresses that will receive the minted tokens.
     * @param frozen ( bool ) true if minted token should be frozen, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintCollectionToManyUsers(
        uint256 collectionId,
        address[] memory to,
        bool frozen,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        uint64 newExpiration = uint64(block.timestamp) + validDuration;
        // First mint all tokens
        for (uint256 i = 0; i < to.length; ++i) {
            uint256 tokedId = lastId + 1 + i;
            _mintToken(collectionId, tokedId, to[i], frozen);
            if (validDuration > 0) {
                setExpiration(tokedId, newExpiration);
            }
        }
        // Last update Last Id with the Collection Id
        lastId += to.length;
        return true;
    }

    /**
     * @dev Mint many tokens to address.
     * Requires
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param collectionIds ( array uint256 ) Collection Ids to assing to user
     * @param to ( address ) The address that will receive the minted tokens.
     * @param frozen ( bool ) true if minted token should be frozen, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyCollections(
        uint256[] memory collectionIds,
        address to,
        bool frozen,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        // First mint all tokens
        uint64 newExpiration = uint64(block.timestamp) + validDuration;
        for (uint256 i = 0; i < collectionIds.length; ++i) {
            uint256 tokedId = lastId + 1 + i;
            _mintToken(collectionIds[i], tokedId, to, frozen);
            if (validDuration > 0) {
                setExpiration(tokedId, newExpiration);
            }
        }
        // Last update Last Id with the Collections Id
        lastId += collectionIds.length;
        return true;
    }

    /**
     * @dev Internal function to mint tokens
     * @param collectionId ( uint256 ) collectionId for the new token
     * @param tokenId ( uint256 ) The token id to mint. Minted by message.sender
     * @param to ( address ) The address that will receive the minted tokens.
     * @param frozen ( bool ) true if minted token should be frozen, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 collectionId,
        uint256 tokenId,
        address to,
        bool frozen,
        uint64 validDuration
    ) internal returns (bool) {
        _mint(to, tokenId);
        _tokenCollection[tokenId] = collectionId;
        if (frozen) {
            freeze(tokenId);
        }
        if (validDuration != 0) {
            _extendSubscription(tokenId, validDuration);
        }
        return true;
    }

    /**
     * @dev Internal function to mint tokens
     * @param collectionId ( uint256 ) collectionId for the new token
     * @param tokenId ( uint256 ) The token id to mint. Minted by message.sender
     * @param to ( address ) The address that will receive the minted tokens.
     * @param frozen ( bool ) true if minted token should be frozen, else false
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 collectionId,
        uint256 tokenId,
        address to,
        bool frozen
    ) internal returns (bool) {
        _mint(to, tokenId);
        _tokenCollection[tokenId] = collectionId;
        if (frozen) {
            freeze(tokenId);
        }
        return true;
    }

    /**
     * @dev Implements pause and frozen functionality.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable)
        whenNotPaused
        whenNotFrozen(tokenId)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /************************************************************************************************
     * Royalites
     ************************************************************************************************/
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
        uint256 _collectionId = tokenCollection(_tokenId);

        RoyaltyInfo memory royalty = _collectionRoyaltyInfo[_collectionId];

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
        onlyOwnerOrAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function removeDefaultRoyalty() public onlyOwnerOrAdmin {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * @param receiver Address to receive the royalties. Cannot be the zero address.
     * @param feeNumerator Size of the royalty in basis points. Cannot be greater than the fee denominator (10000).
     */
    function updateCollectionRoyalty(
        uint256 collectionId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwnerOrAdmin {
        _setCollectionRoyalty(collectionId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function removeCollectionRoyalty(uint256 collectionId)
        public
        onlyOwnerOrAdmin
    {
        _resetCollectionRoyalty(collectionId);
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
    function _setCollectionRoyalty(
        uint256 collectionId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _collectionRoyaltyInfo[collectionId] = RoyaltyInfo(
            receiver,
            feeNumerator
        );
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetCollectionRoyalty(uint256 collectionId) internal virtual {
        delete _collectionRoyaltyInfo[collectionId];
    }

    /************************************************************************************************
     * Burn
     ************************************************************************************************/
    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenCollection[tokenId];
        delete _tokenFrozen[tokenId];
        delete _expirations[tokenId];
    }

    /************************************************************************************************
     * Seaport
     ************************************************************************************************/
    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     * See: https://github.com/ProjectOpenSea/seaport
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721Upgradeable)
        returns (bool isOperator)
    {
        // if Seaport Proxy Address is detected, auto-return true
        // or if the operator is an admin user, auto-return true
        if (
            _operator == address(0x00000000006c3852cbEf3e08E8dF289169EdE581) ||
            isAdmin(_operator)
        ) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721Upgradeable.isApprovedForAll(_owner, _operator);
    }

    /************************************************************************************************
     * Admin
     ************************************************************************************************/
    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC5643).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows the owner to update the trusted forwarder for erc2771 transactions
     * @param forwarder ( address ) contract address of the new forwarder
     */
    function setTurstedForwarder(address forwarder) public onlyOwnerOrAdmin {
        _setTrustedForwarder(forwarder);
    }
}
