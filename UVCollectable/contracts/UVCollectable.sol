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
import "./operator-filter-registry/DefaultOperatorFiltererUpgradeable.sol";
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
    ERC2771Recipient,
    DefaultOperatorFiltererUpgradeable
{
    /************************************************************************************************
     * Events
     ************************************************************************************************/
    /**
     * @dev Emmited when token is locked
     */
    event Locked(uint256 tokenId);

    /**
     * @dev Emmited when token is unlocked by function call
     */
    event Unlocked(uint256 tokenId);

    /**
     * @dev Emmited when an admin is added
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

    // Locked tokens
    mapping(uint256 => bool) private _tokenLocked;

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

    function initialize(
        string memory __name,
        string memory __symbol,
        string memory __contractURI,
        address[] calldata __admins
    ) public initializer {
        __ERC721_init(__name, __symbol);
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        updateContractURI(__contractURI);

        for (uint256 i = 0; i < __admins.length; ++i) {
            addAdmin(__admins[i]);
        }
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
     * @param admin ( address )
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * @dev Grants admin user privilages to newAdmin.
     * @param newAdmin ( address )
     */
    function addAdmin(address newAdmin) public onlyOwnerOrAdmin {
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
        uint256 collectionId = tokenCollection(tokenId);

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
     * @param collectionId ( uint256 ) The Event Id you want to get the URI
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
     * Collections
     ************************************************************************************************/
    /**
     * @dev Gets the Collection Id for the token
     * @param tokenId ( uint256 ) The Token Id you want to query
     * @return ( uint256 ) representing the Collection id for the token
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
     * Locked Tokens
     ************************************************************************************************/
    /**
     * @dev Gets the token locked status
     * @param tokenId ( uint256 ) The token id to check.
     * @return bool representing the token locked status
     */
    function isLocked(uint256 tokenId) public view returns (bool) {
        return _tokenLocked[tokenId];
    }

    /**
     * @dev Modifier to make a function callable only when the toke is not locked.
     * @param tokenId ( uint256 ) The token id to check.
     */
    modifier whenNotLocked(uint256 tokenId) {
        require(!this.isLocked(tokenId), "Token is locked");
        _;
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireLocked(uint256 tokenId) internal view virtual {
        _requireMinted(tokenId);
        require(isLocked(tokenId), "Token is not locked");
    }

    /**
     * @dev Locks a specific ERC721 token.
     * Requires
     * - The sender has to be the approved opperator
     * - The contract does not have to be paused
     * - The token cannot already be locked
     * @param tokenId ( uint256 ) Id of the ERC721 token to be locked.
     */
    function lockToken(uint256 tokenId)
        external
        virtual
        whenNotPaused
        whenNotLocked(tokenId)
    {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not token owner or approved"
        );
        _lock(tokenId);
    }

    /**
     * @dev Unlock a specific ERC721 token.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * - The token must be locked
     * @param tokenId ( uint256 ) Id of the ERC721 token to be unlocked.
     */
    function unlockToken(uint256 tokenId)
        external
        virtual
        onlyOwnerOrAdmin
        whenNotPaused
    {
        _requireLocked(tokenId);
        _unlock(tokenId);
    }

    /**
     * @dev Internal function to lock a specific token
     * @param tokenId ( uint256 ) Id of the token being locked by the _msgSender
     */
    function _lock(uint256 tokenId) internal {
        _tokenLocked[tokenId] = true;
        emit Locked(tokenId);
    }

    /**
     * @dev Internal function to unlock a specific token
     * @param tokenId ( uint256 ) Id of the token being locked by the _msgSender
     */
    function _unlock(uint256 tokenId) internal {
        delete _tokenLocked[tokenId];
        emit Unlocked(tokenId);
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
     * @param recipient ( address ) address where the token will be sent
     */
    function reclaimToken(uint256 tokenId, address recipient)
        public
        onlyOwnerOrAdmin
    {
        _requireLocked(tokenId);
        _unlock(tokenId);
        _transfer(ownerOf(tokenId), recipient, tokenId);
    }

    /************************************************************************************************
     * Minting
     ************************************************************************************************/
    /**
     * @dev Mint token to address.
     * Requires
     * - The msg sender to be the onwer
     * - The contract does not have to be paused
     * @param collectionId ( uint256 ) CollectionId for the new token
     * @param to ( address ) The address that will receive the minted tokens.
     * @param locked ( bool ) true if minted token should be locked, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 collectionId,
        address to,
        bool locked,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        // Updates Last Id first to not overlap
        lastId += 1;
        return _mintToken(collectionId, lastId, to, locked, validDuration);
    }

    /**
     * @dev Mint token to many addresses.
     * Requires
     * - The msg sender to be the owner
     * - The contract does not have to be paused
     * @param collectionId ( uint256 ) CollectionId for the new token
     * @param to ( array of address ) The addresses that will receive the minted tokens.
     * @param locked ( bool ) true if minted token should be locked, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintCollectionToManyUsers(
        uint256 collectionId,
        address[] calldata to,
        bool locked,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        // First mint all tokens
        if (validDuration > 0) {
            uint256 tokenId;
            uint64 newExpiration = uint64(block.timestamp) + validDuration;
            for (uint256 i = 0; i < to.length; ++i) {
                tokenId = lastId + 1 + i;
                _mintTokenV2(collectionId, tokenId, to[i], locked);
                setExpiration(tokenId, newExpiration);
            }
        } else {
            for (uint256 i = 0; i < to.length; ++i) {
                _mintTokenV2(collectionId, lastId + 1 + i, to[i], locked);
            }
        }
        // Last update Last Id
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
     * @param locked ( bool ) true if minted token should be locked, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyCollections(
        uint256[] calldata collectionIds,
        address to,
        bool locked,
        uint64 validDuration
    ) public whenNotPaused onlyOwnerOrAdmin returns (bool) {
        // First mint all tokens
        if (validDuration > 0) {
            uint256 tokenId;
            uint64 newExpiration = uint64(block.timestamp) + validDuration;
            for (uint256 i = 0; i < collectionIds.length; ++i) {
                tokenId = lastId + 1 + i;
                _mintTokenV2(collectionIds[i], tokenId, to, locked);
                setExpiration(tokenId, newExpiration);
            }
        } else {
            for (uint256 i = 0; i < collectionIds.length; ++i) {
                _mintTokenV2(collectionIds[i], lastId + 1 + i, to, locked);
            }
        }
        // Last update Last Id
        lastId += collectionIds.length;
        return true;
    }

    /**
     * @dev Internal function to mint tokens
     * @param collectionId ( uint256 ) CollectionId for the new token
     * @param tokenId ( uint256 ) The token id to mint. Minted by message.sender
     * @param to ( address ) The address that will receive the minted tokens.
     * @param locked ( bool ) true if minted token should be locked, else false
     * @param validDuration ( unit64 ) duration in seconds that the minted token is valid for, 0 if not subscription token
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 collectionId,
        uint256 tokenId,
        address to,
        bool locked,
        uint64 validDuration
    ) internal returns (bool) {
        _mint(to, tokenId);
        _tokenCollection[tokenId] = collectionId;
        if (locked) {
            _lock(tokenId);
        }
        if (validDuration != 0) {
            _extendSubscription(tokenId, validDuration);
        }
        return true;
    }

    /**
     * @dev Internal function to mint tokens without subscription
     * @param collectionId ( uint256 ) CollectionId for the new token
     * @param tokenId ( uint256 ) The token id to mint. Minted by message.sender
     * @param to ( address ) The address that will receive the minted tokens.
     * @param locked ( bool ) true if minted token should be locked, else false
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintTokenV2(
        uint256 collectionId,
        uint256 tokenId,
        address to,
        bool locked
    ) internal returns (bool) {
        _mint(to, tokenId);
        _tokenCollection[tokenId] = collectionId;
        if (locked) {
            _lock(tokenId);
        }
        return true;
    }

    /**
     * @dev Implements pause and locked functionality.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable)
        whenNotPaused
        whenNotLocked(tokenId)
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
        delete _tokenLocked[tokenId];
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
        // if Seaport Proxy Address or admin user is detected, auto-return true
        if (
            _operator == address(0x00000000006c3852cbEf3e08E8dF289169EdE581) ||
            isAdmin(_operator)
        ) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /************************************************************************************************
     * Operator Filter Registry: https://github.com/ProjectOpenSea/operator-filter-registry
     ************************************************************************************************/
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
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
