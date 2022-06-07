# AirdropNftSolidity
Training on ERC721, Upgradeable smart contract etc ...

## Constraints for this project

 ### Constraint #1 

 ==> I have to airdop 100 NFTs : not more than 100

###  Constraint #2
==> We don't know the future owners of the NFT but they have to claim their NFT on a web page. <br>
    So, the only to claim the Airdrop is to use the website.


###  Constraint #3
==> Gas fees must be paid by the one who is airdropped 

### Constraint #4
==> The smart contract must be upgradeable




## Proposed Solution

### Constraint #1 : Limit the count NFT for the Airdrop
For this constraint, it can be directly implements in the solidity smart contract.<br>
C.f. the variable _max_supply_

### Constraint #2 : Require users to use the website to claim the airdrop

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



Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
