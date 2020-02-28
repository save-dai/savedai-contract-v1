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
const ForceSend = artifacts.require("ForceSend");

// ABI
const erc20ABI = require("./abi/erc20");

// Dai
const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const daiContract = new web3.eth.Contract(erc20ABI, daiAddress);

// Utils
const getDaiBalance = async account => {
  return daiContract.methods.balanceOf(account).call();
};

const myWallet = "0xb8ff821e6a8750c97d081c695dd568681be6ec34";

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
      saveDAI = await SaveDAI.new();
    });

    it('should return my balance', async function () {
      const balance = await getDaiBalance(myWallet);
      const kseniyaBalance = 49361910000000000;
      assert.equal(balance, kseniyaBalance);
    });

    it('it should mint Dai', async function () {
      // Send 1 eth to daiAddress to have gas to mint.
      // Uses ForceSend contract, otherwise just sending
      // a normal tx will revert.
      const forceSend = await ForceSend.new();
      await forceSend.go(daiAddress, { value: ether("1") });

      const ethBalance = await balance.current(daiAddress);
      console.log(ethBalance.toString())

      const ethBalance2 = await web3.eth.getBalance(daiAddress)
      console.log(ethBalance2.toString())

      await daiContract.methods
      .mint(myWallet, ether("100").toString())
      .send({ from: daiAddress });

      const daiBalance = await getDaiBalance(myWallet);
      console.log(daiBalance);

    });
    
    // // TO DO TESTS
    // describe('_buy', function () {
    // });
});
