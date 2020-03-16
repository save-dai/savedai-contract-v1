const Web3 = require('web3');
const provider = 'http://127.0.0.1:8545';
const web3Provider = new Web3.providers.HttpProvider(provider);
const web3 = new Web3(web3Provider);

const { expect } = require('chai');
const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  ether,
  balance,
} = require('@openzeppelin/test-helpers');
const { asyncForEach } = require('./utils');

const SaveDAI = artifacts.require('SaveDAI');
const ERC20 = artifacts.require('ERC20');
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

const ocDaiAddress = "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33";

// Utils
const getDaiBalance = async account => {
  return daiContract.methods.balanceOf(account).call();
};

const userWallet = "0xdfbaf3e4c7496dad574a1b842bc85b402bdc298d";

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
      savedai = await SaveDAI.new();
      savedaiAddress = savedai.address;
      savedaiInstance = await SaveDAI.at(savedaiAddress);

      // await ERC20.new();
      daiInstance = await ERC20.at(daiAddress);
      ocDaiInstance = await ERC20.at(ocDaiAddress);

      // Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: userWallet,
        value: ether('1')
      });
    });

    it('should transfer', async () => {
      const userWalletdaiBalance = await savedaiInstance.testDAIBalance.call({from: userWallet});
      console.log(userWalletdaiBalance.toString());

      const userWalletdaiBalance1 = await getDaiBalance(userWallet);
      console.log(userWalletdaiBalance1.toString());

      const savedaiBalance = await getDaiBalance(savedaiAddress);
      console.log(savedaiBalance.toString());

      const k = await daiInstance.balanceOf(userWallet);
      console.log(k.toString());

      const address = await savedaiInstance.getExchange(ocDaiAddress);
      console.log(address);

      // approve DAI uniswap exchange to swap tokens for me
      await daiInstance.approve(address, 1000, {from: userWallet});

      await savedaiInstance.testTransfer(1000, {from: userWallet, gas: '6000000'});
      const savedaiBalance2 = await getDaiBalance(savedaiAddress);
      console.log(savedaiBalance2.toString());
    });

    it('should send ether to the DAI address', async () => {
      const ethBalance = await balance.current(userWallet);
      expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
    });
      
    // // TO DO TESTS
    describe('mint', function () {
      it('should return exchange', async function () {
        const address = await savedaiInstance.getExchange(ocDaiAddress);
        const address2 = await uniswapFactoryContract.methods.getExchange(ocDaiAddress).call();
        const supply = await savedaiInstance.getSupply(ocDaiAddress);
        console.log(address);
        console.log(address2);
        console.log(supply.toString());
      });
      it('should return amount', async function () {
        const amount = '100';
        const amounthey = await savedaiInstance.premiumToPay(ocDaiAddress, daiAddress, amount );
        console.log(amounthey.toString());
      });
      it('should return amount', async function () {
        const amount = web3.utils.toWei('100', 'ether');
        console.log(amount.toString())
        const amounthey = await savedaiInstance.tokensToBuy(ocDaiAddress, daiAddress, amount );
        console.log(amounthey.toNumber());
      });
      it('should buy', async function () {
        const amount = web3.utils.toWei('100', 'ether');
        // const address = await savedaiInstance.getExchange(daiAddress);
        // console.log(address);
        const balance = await getDaiBalance(userWallet);
        console.log(balance.toString())

        // await daiInstance.approve(address, 1000, {from: userWallet});
        // allow SAVEDAI to transfer tokens on my behalf
        await daiInstance.approve(savedaiAddress, amount, {from: userWallet});

        await savedaiInstance._uniswapBuyOCDAI(amount, {from: userWallet});
        const x = await ocDaiInstance.balanceOf(savedaiAddress);
        console.log(x.toString());

        const savedaiBalance2 = await getDaiBalance(savedaiAddress);
        console.log(savedaiBalance2.toString());

      });
      it('should buy', async function () {
        const amount = web3.utils.toWei('100', 'ether');
        // const address = await savedaiInstance.getExchange(daiAddress);
        // console.log(address);
        const balance = await getDaiBalance(userWallet);
        console.log(balance.toString())

        // await daiInstance.approve(address, 1000, {from: userWallet});
        // allow SAVEDAI to transfer tokens on my behalf
        await daiInstance.approve(savedaiAddress, amount, {from: userWallet});

        await savedaiInstance._uniswapBuyOCDAI(amount, {from: userWallet});
        const x = await ocDaiInstance.balanceOf(savedaiAddress);
        console.log(x.toString());

        const savedaiBalance2 = await getDaiBalance(savedaiAddress);
        console.log(savedaiBalance2.toString());

      });
    });
});
