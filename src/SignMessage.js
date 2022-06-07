require("dotenv").config();

import { ethers } from "ethers";
import {axios} from "axios";

//GET the value of the WEB_AUTH_TOKEN  in the .env file
const WEB_AUTH_TOKEN = process.env.WEB_AUTH_TOKEN


/** Sign message with a web authentication token*/
const signMessage = async () => {
    try {
      if (!window.ethereum)
        throw new Error("No crypto wallet found. Please install it.");
  
      await window.ethereum.send("eth_requestAccounts");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const signature = await signer.signMessage(WEB_AUTH_TOKEN);
      
      return {
        signature
      };
    } catch (err) {
      console.log(err)
    }
  };
  