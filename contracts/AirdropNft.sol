// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 Contrainte n°1 : 
 ----------------
 La contrainte qui consiste à forcément passer par un site web pour pouvoir minter un NFT via l'airdrop 
 peut se faire via une signature en utilisant les librairies de signature d'OpenZeppelin.
 Le serveur Web, va signer les wallets qui se connectent sur le site web, envoyer les signatures au front qui 
 va lesenvoyer au smart contract. Le smart contract peut donc vérifier les signatures du msg.sender.
 Si la signature est valide, c'est que l'utilisateur est passé par le site web

 Contrainte n°2 : 
 ----------------
 C'est l'acquéreur du NFT par Airdrop qui doit payer les gas fees.
 Pour ça, on va lui laisser la possibilité de minter le NFT. 
 Ce ne sera pas le Owner du Smart contract qui va minter puis transférer le ownership du NFT 
 à l'utilisateur. Ainsi ce sera le user qui va minter le NFT en payant la transaction ==> Lazy Minting
 On utilisera pour celà, le contrat d'OpenZeppelin "AccessControl"
 
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

    uint256 private max_supply;

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
        require(tokenId <= getMaxSupply(), "All NFT has been airdropped. Sorry !");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {
        
    }

    // Get the max Supply for the Airdrop
    function getMaxSupply() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        return max_supply;
    }

    // Set the max Supply for the Airdrop
    function setMAxSupply(uint256 _max_supply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        max_supply = _max_supply;
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
