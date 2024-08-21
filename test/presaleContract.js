const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("*********** This is Lngb PreSale Contract ***********", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  let LnbgPreSaleContract;
  let USDTToken;
  let USDCToken;
  let lngbToken;

  it("Deploy the contract ", async function () {
    [Owner, otherAccount1, otherAccount2, otherAccount3, otherAccount4] =
      await ethers.getSigners();

    const LnbgCoin = await hre.ethers.getContractFactory("lngbCoin");

    lngbToken = await LnbgCoin.deploy();

    await lngbToken.deployed();

    const usdt = await hre.ethers.getContractFactory("USDTToken");

    USDTToken = await usdt.deploy();

    await USDTToken.deployed();

    const usdc = await hre.ethers.getContractFactory("USDCToken");

    USDCToken = await usdc.deploy();

    await USDCToken.deployed();

    const PreSaleContract = await hre.ethers.getContractFactory(
      "LnbgPreSaleContract"
    );

    LnbgPreSaleContract = await PreSaleContract.deploy(USDCToken.address,USDTToken.address,lngbToken.address);

    await LnbgPreSaleContract.deployed();
    let amountPresale = ethers.utils.parseEther("100000");
    lngbToken.transfer(LnbgPreSaleContract.address,amountPresale);

  });


  it("This should buy Token check with BNB ", async function () {
    const balance2 = await lngbToken.balanceOf(otherAccount1.address);
    console.log("Before Buy This is availabe Lngb In Buyer Account ## ",
      ethers.utils.formatEther(balance2?.toString())
    );

    let sendTokens = ethers.utils.parseEther("100");
    let tokenPrice = LnbgPreSaleContract.sellTokenInETHPrice(sendTokens,(0.1 * 10 ** 18))
    LnbgPreSaleContract.connect(otherAccount1).buyWithBNB(sendTokens,{value:tokenPrice});
    
    const balance = await lngbToken.balanceOf(otherAccount1.address);
    console.log("After Buy This is availabe Lngb In Buyer Account ## ",
      ethers.utils.formatEther(balance?.toString())
    );
  });

});
