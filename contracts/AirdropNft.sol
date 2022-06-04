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

contract AirdropNft is ERC721, AccessControl {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    uint public constant MAX_SUPPLY = 100;


    constructor() ERC721("AirdropNft", "MTV") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://any-ipfs-url.com";
    }

    function claimNft(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_SUPPLY, "All NFT has been airdropped. Sorry !");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
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