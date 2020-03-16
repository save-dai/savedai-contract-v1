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
const ERC20 = artifacts.require('ERC20');

// mainnet addresses
const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const ocDaiAddress = "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33";
const cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
const userWallet = "0xdfbaf3e4c7496dad574a1b842bc85b402bdc298d";

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
      savedai = await SaveDAI.new();
      savedaiAddress = savedai.address;
      savedaiInstance = await SaveDAI.at(savedaiAddress);

      // instantiate mock tokens
      daiInstance = await ERC20.at(daiAddress);
      ocDaiInstance = await ERC20.at(ocDaiAddress);
      cDaiInstance = await ERC20.at(cDaiAddress);

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
      
    // // TO DO TESTS
    describe('mint', function () {
      it('should increase saveDAI balance by amount of ocDAI tokens bought', async function () {
        // amount of ocDAI tokens to buy
        const amount = '100';

        await daiInstance.approve(savedaiAddress, '10000000000000000000000000', {from: userWallet});

        await savedaiInstance._uniswapBuyOCDAI(amount, {from: userWallet});
        const saveDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        assert.equal(amount, saveDAIbalance);
      });
      it('should mintcDAI', async function () {
        const amount = '100';

        await daiInstance.approve(savedaiAddress, amount, {from: userWallet});

        await savedaiInstance._mintcDAI(amount, {from: userWallet});

        const saveDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);
        console.log(saveDAIbalance.toString());
      });
    });
});
