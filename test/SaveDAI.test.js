const Web3 = require('web3');
const provider = 'http://127.0.0.1:8545';
const web3Provider = new Web3.providers.HttpProvider(provider);
const web3 = new Web3(web3Provider);

const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  ether,
  balance,
} = require('@openzeppelin/test-helpers');

const SaveDAI = artifacts.require('SaveDAI');
const UniswapFactory = artifacts.require('UniswapFactoryInterface');
const UniswapExchange = artifacts.require('UniswapExchangeInterface');

// ABI
const erc20ABI = require("./abi/erc20");
const uniswapFactoryABI = require("./abi/uniswapFactory.js");

const uniswapFactoryAddress = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95';
const uniswapFactoryContract = new web3.eth.Contract(uniswapFactoryABI, uniswapFactoryAddress);

// Dai
const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const daiContract = new web3.eth.Contract(erc20ABI, daiAddress);

// Utils
const getDaiBalance = async account => {
  return daiContract.methods.balanceOf(account).call();
};

const userWallet = "0xdfbaf3e4c7496dad574a1b842bc85b402bdc298d";

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
      savedai = await SaveDAI.new();
      savedaiInstance = await SaveDAI.at(savedai.address);
    });

    it('should have a balance of DAI', async function () {
      const balance = await getDaiBalance(userWallet);
      assert.isAbove(Number(balance), 0);
    });
    
    // // TO DO TESTS
    describe('mint', function () {
      it('should return exchange', async function () {
        const address = await savedaiInstance.getExchange(daiAddress);
        // const address = await uniswapFactoryContract.methods.getExchange(daiAddress).call();
        console.log(address);
      });
    });
});
