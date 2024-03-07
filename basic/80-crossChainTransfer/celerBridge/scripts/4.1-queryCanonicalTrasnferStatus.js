// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {ethers} = require("hardhat");
const fetch = require("node-fetch");

const {
  readRedpacketDeployment,
} = require("../utils");

const request = (url, params = {}, method = "GET") => {
  let options = {
    method,
  };
  if ("GET" === method) {
    url += "?" + new URLSearchParams(params).toString();
  } else {
    options.body = JSON.stringify(params);
  }

  return fetch(url, options).then((response) => response.json());
};


async function getTransferStatus(transferID){
  const fetchPostRes = await request(
    "https://cbridge-prod2.celer.app/v2/getTransferStatus",
    {
      transfer_id:
      transferID,
    },
    "POST"
  );

  return fetchPostRes
}


async function main() {
  const deployment = readRedpacketDeployment();
  
  // get transfer status
  // refer to: https://cbridge-docs.celer.network/developer/api-reference/gateway-gettransferstatus
  console.log("Begin to check cross chain transfer result")
  let bridgeID = deployment.canonicalCelerBridgeTransferID
  let transferStatus = await getTransferStatus(bridgeID)
  console.log(transferStatus)
  switch(transferStatus.status){
    case 0:
      console.log("Placeholder status")
      break; 
    case 1:
      console.log("cBridge gateway monitoring on-chain transaction")
      break; 
    case 2:
      console.log("transfer failed, no need to refund")
      break;
    case 3:
      console.log("cBridge gateway waiting for Celer SGN confirmation")
      break;
    case 4:
      console.log("waiting for user's fund release on destination chain")
      break;
    case 5:
      console.log("Transfer completed")
      break;
    case 6:
      console.log("Transfer failed, should trigger refund flow, whether it is Pool-Based or Mint/Burn refund​")
      break;
    case 7:
      console.log("cBridge gateway is preparing information for user's transfer refund​")
      break;
    case 8:
      console.log("The user should submit on-chain refund transaction based on information provided by this api​")
      break;
    case 9:
      console.log("cBridge monitoring transfer refund status on source chain​")
      break;
    case 10:
      console.log("Transfer refund completed​")
      break;
    case 11:
      console.log("Transfer is put into a delayed execution queue​")
      break;
  }
  

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
