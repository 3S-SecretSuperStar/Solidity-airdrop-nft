# AirdropNftSolidity Description
This project is a coding/brainstorming challenge with some constraints described below.
It enables me to train on ERC721, Upgradeable smart contract, Roles, OpenZeppelin standards, etc ...

## Constraints for this project

 ### Constraint #1 

 ==> I have to airdop 100 NFTs : not more than 100

### Constraint #2

==> We don't know the future owners of the NFT but they have to claim their NFT on a web page. <br>
    So, the only to claim the Airdrop is to use the website.


### Constraint #3

==> Gas fees must be paid by the one who is airdropped 

### Constraint #4

==> The smart contract must be upgradeable




## Proposed Solution
The main smart contract for this challenge is **AirdropNft.sol** smart contract.
This contract is a model for the constraints I was given.
This contract was not tested so it probably doesn't work. 
It's just a model written for a challenge and to learn about all NDT standards.

### Constraint #1 : Limit the count NFT for the Airdrop

For this constraint, it can be directly implements in the solidity smart contract.<br>
C.f. the variable _max_supply_

### Constraint #2 : Require users to use the website to claim the airdrop
The solution I proposed is the following : We share a WEB_AUTH_TOKEN between the website and the smart contract like 
the use of JWT for instance to check granted users for instance on websites.

Step 1) <br>
The user connects to the website with his Metamask.
The website knows his account.

Step 2) <br>
The user wants to mint a NFT on the website. He must click on a button "Claim Airdrop"

Step 3) <br>
The front app javascript is implemented on this button in order to use the "signMessage" of the library "ether.js".<br>
With this library, a hash is generated and this hash depends on : 

 - the public key of the user (Metamask account)
 - a string

 For the string we decide to concat a secret WEB_AUTH_TOKEN (set in a _.env_ file) with the current token Id of the NFT.<br>
 For security, we can, for instance, set the WEB_AUTH_TOKEN with the value of sha256('metav.rs') but it can be other value.

So a hash of this concatenation is used with ether.js like this : 

```js
const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message+tokenId))
```

where _message_ is the _WEB_AUTH_TOKEN_ set in the _.env_ file

Then, we implements the _signMessage_ function of _ether.js_ like this : 

```js
const signature = await signer.signMessage(ethers.utils.arrayify(hash))
```

So the generated signature depends on the tokenId, the address of the user, the _WEB_AUTH_TOKEN_

Step 4) <br>
The front app calls the smart contract by passing the generetad signature 

```js
await contract.claimAirdrop(user_address, signature)
```

Step 5) <br>
The smart contract will decode the signature with the WEB_AUTH_TOKEN which is the same than the token implemented on the web site and used to generate the signature



Step 6) <br>
The smart contract know the WEB_AUTH_TOKEN because it's a storage private variable. <br>
It's the same value than the one set in the website. So, the Website and the smart contract share the same token.<br>
This token is used to encode the signature on the website and decode the signer in the smart contract

Step 7) <br>
That's it !
With this solution, the only way to claim the Airdrop is to use the website. You can not claim in other ways.




### Constraint #3 : Gas fees must be paid by the one who is airdropped 

For that, I chose the "Lazy Minting" pattern.
That's not the owner that mint the NFT and transfer ownership to the one that is airdropped.<br>
It's directly the user that mint the NFT so he pays the fees.
We can see it in the smart contract _AirdropNft.sol_ by using the OpenZeppelin standard _AccessControlUpgradeable_. <br>
We define a MINTER_ROLE.
The _claimAirdrop_ function uses the modifier _onlyRole(MINTER_ROLE)_. <br>
This way, everyone who is defined as MINTER can mint the NFT, pay the fees en get it.

### Constraint #4 : The smart contract must be upgradeable

For that, we use the OpenZeppelin standard _UUPSUpgradeable_.
That way, we can upgrade the smart contract.

For instance, imagine the following scenario.<br><br>
Scenario 1) <br>
The WEB_AUTH_TOKEN is compromised and we want to modify it.<br>
We can upgrade the smart contract and use the standard _Pausable_ of OpenZeppelin to pause the Airdrop while we find the potential secutity failures on the web site


# Remarks

The _VerifySignature.sol_ smart contract was written to test signature in the front side (JS) 
or the Back side (Solidity)

## Install dependencies

```shell
npm install
```

## Compile smart contracts

```shell
npx hardhat compile
```

## Test the _VerifySignature.sol_ smart contract

```shell
npx hardhat test scripts/verify-signature.js
```

# Author

Gilles Bruno
