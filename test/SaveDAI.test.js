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

const SaveDAI = artifacts.require('SaveDAI');
const CTokenInterface = artifacts.require('CTokenInterface');
const ERC20 = artifacts.require('ERC20');

// mainnet addresses
const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const ocDaiAddress = "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33";
const cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
const userWallet = "0xfc9362c9aa1e4c7460f1cf49466e385a507dfb2b";

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
      savedai = await SaveDAI.new();
      savedaiAddress = savedai.address;
      savedaiInstance = await SaveDAI.at(savedaiAddress);

      // instantiate mock tokens
      daiInstance = await ERC20.at(daiAddress);
      ocDaiInstance = await ERC20.at(ocDaiAddress);
      cDaiInstance = await CTokenInterface.at(cDaiAddress);

      // Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: userWallet,
        value: ether('1')
      });
    });

    it('user wallet should have DAI balance', async () => {
      const userWalletBalance = await daiInstance.balanceOf(userWallet);
      expect(new BN(userWalletBalance)).to.be.bignumber.least(new BN(ether('0.1')));
    });

    it('should send ether to the DAI address', async () => {
      const ethBalance = await balance.current(userWallet);
      expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
    });
      
    describe('mint', async function () {
      // amount of tokens to mint
      const amount = '100';
      it('should mint saveDAI tokens', async function () {
        // calculate amount needed for approval
        const daiNeededForPremium = await savedaiInstance.premiumToPay(amount);
        const dai = ether(amount);
        const totalTransfer = daiNeededForPremium.add(dai);

        // approve saveDAI contract
        await daiInstance.approve(savedaiAddress, totalTransfer, {from: userWallet});

        // mint tokens
        await savedaiInstance.mint(amount, {from: userWallet});

        const ocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        assert.equal(amount, ocDAIbalance);
        console.log('ocDAI tokens minted, in saveDAI contract', ocDAIbalance.toString())

        let saveDAIbalance2 = await cDaiInstance.balanceOf(savedaiAddress);
        saveDAIbalance2 = saveDAIbalance2 / 1e8;
        console.log('cDAI tokens minted, in saveDAI contract', saveDAIbalance2.toString())

        let underlying = await cDaiInstance.balanceOfUnderlying.call(savedaiAddress);
        underlying = underlying / 1e18;
        console.log('underlying balance of cDAI tokens', underlying.toString())

        const saveDaiMinted = await savedaiInstance.balanceOf(userWallet);
        console.log('saveDAI tokens minted, in userWallet', saveDaiMinted.toString())
        assert.equal(amount, saveDaiMinted);
      });
      it('should decrease userWallet DAI balance', async function () {
        let initialBalance = await daiInstance.balanceOf(userWallet);

        // calculate amount needed for approval
        const daiNeededForPremium = await savedaiInstance.premiumToPay(amount);
        const dai = ether(amount);
        const totalTransfer = daiNeededForPremium.add(dai);

        // approve saveDAI contract
        await daiInstance.approve(savedaiAddress, totalTransfer, {from: userWallet});

        // mint tokens
        await savedaiInstance.mint(amount, {from: userWallet});

        const endingBalance = await daiInstance.balanceOf(userWallet);

        const diff = initialBalance.sub(endingBalance);
        assert.equal(totalTransfer.toString(), diff.toString());
      });
    });
});
