const SaveDAI = artifacts.require("SaveDAI");
const helpers = require("../test/helpers/helpers.js");

const SaveTokenFarmer = artifacts.require('SaveTokenFarmer');

module.exports = function (deployer) {
  deployer.then(async () => {
    let uniswapFactoryAddr;
    let cDaiAddr;
    let ocDaiAddr;
    let daiAddr;
    if ((await web3.eth.net.getId()) == 4) {
      // Rinkeby
      uniswapFactoryAddr = "0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36";
      cDaiAddr = "0x6d7f0754ffeb405d23c51ce938289d4835be3b14";
      ocDaiAddr = "0x57cC8708eFEB7f7D42E4d73ab9120BC275f1DB59";
      daiAddr = "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa";
    } else if ((await web3.eth.net.getId()) == 42) {
      // Kovan
      uniswapFactoryAddr = "0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30";
      cDaiAddr = "0xe7bc397DBd069fC7d0109C0636d06888bb50668c";
      ocDaiAddr = "0xd344828e67444f0921822e83d83d009B85B04454";
      daiAddr = "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa";
    } else if ((await web3.eth.net.getId()) == 1) {
      // Mainnet
      uniswapFactoryAddr = "0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95";
      cDaiAddr = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
      ocDaiAddr = "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33";
      daiAddr = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    } else {
      // local ganache
      uniswapFactoryAddr = "0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95";
      cDaiAddr = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
      ocDaiAddr = "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33";
      daiAddr = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    }

    // deploys the farmer's logic contract
    async function deployFarmer () {
      saveTokenFarmer = await SaveTokenFarmer.new();
      return saveTokenFarmer.address;
    }

    // deploys the farmer's logic contract
    const saveTokenFarmerAddress = await deployFarmer();

    // For all testnets / mainnets
    const saveDAI = await deployer.deploy(
      SaveDAI, uniswapFactoryAddr, cDaiAddr, ocDaiAddr, daiAddr, saveTokenFarmerAddress
    );
    console.log("SaveDAI ", saveDAI.address.toString());
  })
};