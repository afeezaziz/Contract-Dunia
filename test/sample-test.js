/* jshint expr: true */ 
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dunia V1", function () {

  let dunia;
  let pemilik;

  beforeEach(async function () {
    const DuniaV1 = await ethers.getContractFactory("DuniaV1");
    duniaV1 = await DuniaV1.deploy();
    [pemilik] = await ethers.getSigners();    
    
  });  

  
  it("Pemilik dunia adalah msg.sender", async function () {
    expect(await dunia.pemilik()).to.equal(pemilik.address);
  });

});