// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 Make second version of the Smart contract to update the 'claimAirdrop' function for instance
 */

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MyToken is Initializable, ERC721Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint public constant MAX_SUPPLY = 100;

    //The WEB_AUTH_TOKEN is shared between the webserver of the website and the smart contract
    string private WEB_AUTH_TOKEN;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("MyToken", "MTK");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://metav.rs/airdrop/nft/";
    }

    function claimAirdrop(address to, bytes memory signature, string calldata message) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(_verify(_hash(to, tokenId, message), signature), "You are not eligible for this Airdrop !");
        require(tokenId <= MAX_SUPPLY, "All NFT has been airdropped. Sorry !");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {
        
    }

    function getWebAuthToken() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory){
        return WEB_AUTH_TOKEN;
    }

    // Ex : setWebAuthToken('fd642f38c73ac117987cb5d7891d1d0735083caad4db580103f89d46baf8747d');
    function setWebAuthToken(string memory _webAuthtoken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WEB_AUTH_TOKEN = _webAuthtoken;
    } 

    // Hash the concatenation of the tokenId, the acount and a personal message of the user in order to compare with 
    // the signature in the front app
    function _hash(address account, uint256 tokenId, string calldata message) internal view returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenId, account, message, WEB_AUTH_TOKEN)));
    }

    // Verifiy the eligibility of the airdrop
    function _verify(bytes32 digest, bytes memory signature) internal view returns (bool)
    {
        return hasRole(MINTER_ROLE, ECDSA.recover(digest, signature));
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
