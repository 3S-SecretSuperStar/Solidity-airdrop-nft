require("dotenv").config();
const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("VerifySignature", function () {
  it("Check signature", async function () {
    const accounts = await ethers.getSigners(2)

    const VerifySignature = await ethers.getContractFactory("VerifySignature")
    const contract = await VerifySignature.deploy()
    await contract.deployed()

    // const PRIV_KEY = "0x..."
    // const signer = new ethers.Wallet(PRIV_KEY)
    //GET the value of the WEB_AUTH_TOKEN  in the .env file
    const WEB_AUTH_TOKEN = process.env.WEB_AUTH_TOKEN
    console.log('WEB_AUTH_TOKEN : '+WEB_AUTH_TOKEN)
    const signer = accounts[0]
    let to = accounts[1].address
    //const amount = 999
    const message = WEB_AUTH_TOKEN
    const tokenId = "12"

    to = ethers.utils.getAddress(to)

    //Hash with smart contract
    const hash = await contract.getMessageHash(message, tokenId)
    //Hash with ether.js
    to = ethers.utils.getAddress(to)
    const hash_front = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message+tokenId))

    const sig = await signer.signMessage(ethers.utils.arrayify(hash))

    const ethHash = await contract.getEthSignedMessageHash(hash)

    console.log("signer          ", signer.address)
    console.log("recovered signer", await contract.recoverSigner(ethHash, sig))

    // Correct signature and message returns true
    expect(
      await contract.verify(signer.address, message, tokenId, sig)
    ).to.equal(true)

    // Incorrect message returns false
    expect(
      await contract.verify(signer.address, message+'0', tokenId, sig)
    ).to.equal(false)
  })
})