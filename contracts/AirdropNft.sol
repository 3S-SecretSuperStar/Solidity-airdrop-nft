// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

    // @param _to : the address of the user that wants to be airdropped
    // @param _message : the WEB_AUTH_TOKEN = The token that is shared between the website and the smart contract
    // @param _tokenId : the tokenId to airdrop
    function claimAirdrop(address _to, bytes memory _signature) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        string memory message = getWebAuthToken();
        require(verify(_to, message, tokenId, _signature), "You are not eligible for this Airdrop !");
        require(tokenId <= getMaxSupply(), "All NFT have been airdropped. Sorry !");
        _safeMint(_to, tokenId);
        _tokenIdCounter.increment();
    }

    // @dev : Methods from the OpenZeppelin standrad UUPS
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {
        
    }

    // @dev : Get the max Supply for the Airdrop
    function getMaxSupply() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        return max_supply;
    }

    // @dev : Set the max Supply for the Airdrop
    function setMAxSupply(uint256 _max_supply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        max_supply = _max_supply;
    } 

    function getWebAuthToken() internal view returns (string memory){
        return WEB_AUTH_TOKEN;
    }

    // Ex : setWebAuthToken('fd642f38c73ac117987cb5d7891d1d0735083caad4db580103f89d46baf8747d');
    function setWebAuthToken(string memory _webAuthtoken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WEB_AUTH_TOKEN = _webAuthtoken;
    } 

    // @param _to : the user of the website that wants to be airdropped
    // @param _message : the WEB_AUTH_TOKEN = The token that is shared between the website and the smart contract
    // @param _tokenId : the tokenId to airdrop
    function getMessageHash(string memory _message, uint _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message, _tokenId));
    }


    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // @param _signer : the address of the user who wants to be airdropped
    // @return : true if the signer os correctly decode AND has a MINTER_ROLE
    function verify(address _signer, string memory _message, uint _tokenId, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_message, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);
        return (signer == _signer && hasRole(MINTER_ROLE, signer));
    }

    // @return : true if the signer matches the signature
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
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
