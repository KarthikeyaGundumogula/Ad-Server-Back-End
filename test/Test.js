const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("server", function () {
  it("should create a native token", async function () {
    const [deployer] = await ethers.getSigners();
    const ServerFactory = await ethers.getContractFactory("Server");
    const server = await ServerFactory.deploy();
    await server.deployed();
    let x = await server.nativeTokenId();
    expect(await x).to.equal(0);
  });
  it("should deployer will be the owner", async function () {
    const [deployer] = await ethers.getSigners();
    const ServerFactory = await ethers.getContractFactory("Server");
    const server = await ServerFactory.deploy();
    await server.deployed();
    let x = await server.owner();
    let y = await deployer.address;
    expect(await x).to.equal(await y);
  });
  it("should create a token", async function () {
    const [deployer] = await ethers.getSigners();
    const ServerFactory = await ethers.getContractFactory("Server");
    const server = await ServerFactory.deploy();
    await server.deployed();
    let x = await server.createAd("karthikeya", 10002920, 10002, 100000000000);
    let y = await server.AdIds();
    expect(await y).to.equal(1);
  });
  it("should return the Ad details of the given AdId", async function () {
    
  })