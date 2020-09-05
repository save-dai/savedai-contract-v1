const { expect } = require('chai');

const {
  // BN,
  // ether,
  // time,
  // balance,
  // expectRevert,
  // expectEvent,
} = require('@openzeppelin/test-helpers');

const ERC20 = artifacts.require('ERC20');
const SaveDAI = artifacts.require('SaveDAI');
const CTokenInterface = artifacts.require('CTokenInterface');
const SaveTokenFarmer = artifacts.require('SaveTokenFarmer');
const UniswapFactoryInterface = artifacts.require('UniswapFactoryInterface');
const UniswapExchangeInterface = artifacts.require('UniswapExchangeInterface');

// mainnet addresses
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const ocDaiAddress = '0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33';
const cDaiAddress = '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643';
const uniswapFactoryAddress = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95';
const userWallet = '0x897607ab556177b0e0938541073ac1e01c55e483';

contract.only('SaveTokenFarmer', function (accounts) {
  owner = accounts[0];
  notOwner = accounts[1];

  beforeEach(async () => {
    // deploys the farmer's logic contract
    saveTokenFarmer = await SaveTokenFarmer.new();
    saveTokenFarmerAddress = saveTokenFarmer.address;

    savedai = await SaveDAI.new(
      uniswapFactoryAddress,
      cDaiAddress,
      ocDaiAddress,
      daiAddress,
      saveTokenFarmerAddress,
    );
    savedaiAddress = savedai.address;
    savedaiInstance = await SaveDAI.at(savedaiAddress);

    // instantiate mock tokens
    daiInstance = await ERC20.at(daiAddress);
    cDaiInstance = await CTokenInterface.at(cDaiAddress);
    uniswapFactory = await UniswapFactoryInterface.at(uniswapFactoryAddress);

    const daiExchangeAddress = await uniswapFactory.getExchange(daiAddress);
    daiExchange = await UniswapExchangeInterface.at(daiExchangeAddress);
  });

  describe('mint', async () => {
    it('should mint the cDai and store it in the SaveTokenFarmer', async () => {

    });
    it('should return the total number of cDai minted', async () => {

    });
  });

  describe('transfer', async () => {
    it('should revert if the cDai transfer fails', async () => {

    });
    it('should transfer the correct amount of cDai', async () => {

    });
	  it('should return true if the transfer is successful', async () => {

	  });
  });
});
