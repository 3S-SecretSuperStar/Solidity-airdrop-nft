// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AirdropNft is ERC721, AccessControl {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    uint public constant MAX_SUPPLY = 100;
    //The WEB_AUTH_TOKEN is shared between the webserver of the website and the smart contract
    string private WEB_AUTH_TOKEN = 'fd642f38c73ac117987cb5d7891d1d0735083caad4db580103f89d46baf8747d';

    constructor() ERC721("AirdropNft", "MTV") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://any-ipfs-url.com";
    }

    // Main fonction : It enables to be airdropped only if a user uses the Airdrop Website
    // The front app requires some infos to be eligible for the airdrop : 
    //    - a message provided by the user
    //    - the id of the NFT he wants
    function claimNft(address to, bytes memory signature, string calldata message) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(_verify(_hash(to, tokenId, message), signature), "You are not eligible for this Airdrop !");
        require(tokenId <= MAX_SUPPLY, "All NFT has been airdropped. Sorry !");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
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
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}