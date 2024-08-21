const { ethers } = require("hardhat");

async function main() {
  console.log("start");
  /////creating token /////////////
  [Owner, otherAccount1] = await ethers.getSigners();

  let USDTToken = "0x55d398326f99059ff775485246999027b3197955";
  let USDCToken = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d";
  let lnbgToken = "0xdB6675D9740f6401DcD0BB3092fa4dc88c2a0F66";

  const LnbgPreSaleContract = await ethers.getContractFactory(
    "LngbPreSaleContract"
  );
  const lnbgPreSaleContract = await LnbgPreSaleContract.deploy(
    USDTToken,
    USDCToken,
    lnbgToken
  );
  await lnbgPreSaleContract.deployed();

  console.log(
    "lnbgPreSaleContract contract address",
    lnbgPreSaleContract.address
  );

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
