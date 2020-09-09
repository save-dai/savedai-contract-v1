const { expect } = require('chai');
const helpers = require('./helpers/helpers.js');

const {
  BN,
  ether,
  balance,
  expectRevert,
} = require('@openzeppelin/test-helpers');

const ERC20 = artifacts.require('ERC20');
const SaveDAI = artifacts.require('SaveDAI');
const CTokenInterface = artifacts.require('CTokenInterface');
const OTokenInterface = artifacts.require('OTokenInterface');
const SaveTokenFarmer = artifacts.require('SaveTokenFarmer');
const UniswapFactoryInterface = artifacts.require('UniswapFactoryInterface');
const UniswapExchangeInterface = artifacts.require('UniswapExchangeInterface');

// mainnet addresses
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const ocDaiAddress = '0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33';
const cDaiAddress = '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643';
const compAddress = '0x897607ab556177b0e0938541073ac1e01c55e483';
const uniswapFactoryAddress = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95';
const userWallet = '0x897607ab556177b0e0938541073ac1e01c55e483';

contract('SaveTokenFarmer', function (accounts) {
  amount = '4892167171';
  newAmount = '9784334342'; // newAmount equals amount value times 2
  owner = accounts[0];
  recipient = accounts[1];

  beforeEach(async () => {
    // deploys the farmer's logic contract
    saveTokenFarmer = await SaveTokenFarmer.new();
    saveTokenFarmerAddress = saveTokenFarmer.address;

    savedai = await SaveDAI.new(
      uniswapFactoryAddress,
      cDaiAddress,
      ocDaiAddress,
      daiAddress,
      compAddress,
      saveTokenFarmerAddress,
    );
    savedaiAddress = savedai.address;
    savedaiInstance = await SaveDAI.at(savedaiAddress);

    // instantiate mock tokens
    daiInstance = await ERC20.at(daiAddress);
    cDaiInstance = await CTokenInterface.at(cDaiAddress);
    ocDaiInstance = await OTokenInterface.at(ocDaiAddress);
    uniswapFactory = await UniswapFactoryInterface.at(uniswapFactoryAddress);

    const ocDaiExchangeAddress = await uniswapFactory.getExchange(ocDaiAddress);
    ocDaiExchange = await UniswapExchangeInterface.at(ocDaiExchangeAddress);
    const daiExchangeAddress = await uniswapFactory.getExchange(daiAddress);
    daiExchange = await UniswapExchangeInterface.at(daiExchangeAddress);

    // Send eth to userAddress to have gas to send an ERC20 tx.
    await web3.eth.sendTransaction({
      from: owner,
      to: userWallet,
      value: ether('1'),
    });
  });

  it('user wallet should have DAI balance', async () => {
    const userWalletBalance = await daiInstance.balanceOf(userWallet);
    expect(new BN(userWalletBalance)).to.be.bignumber.least(new BN(ether('1')));
  });
  it('should send ether to the DAI address', async () => {
    const ethBalance = await balance.current(userWallet);
    expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
  });
  describe('mint', async () => {
    context('when user DOES NOT already have a SaveTokenFarmer', function () {
      it('should deploy proxy for msg.sender and set them as owner', async () => {
        // mint saveDAI tokens
        await helpers.mint(amount, { from: userWallet });

        const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
        saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

        const owner = await saveDaiProxy.owner();

        assert.equal(owner.toLowerCase(), userWallet);
      });
      it('should mint the cDai and store it in the user\'s SaveTokenFarmer', async () => {
        // mint saveDAI tokens
        await helpers.mint(amount, { from: userWallet });

        const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
        saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

        const cDAIbalance = await cDaiInstance.balanceOf(proxyAddress);
        const ocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const saveDaiMinted = await savedaiInstance.balanceOf(userWallet);

        // all token balances should match
        assert.equal(cDAIbalance.toString(), amount);
        assert.equal(ocDAIbalance.toString(), amount);
        assert.equal(saveDaiMinted.toString(), amount);
      });
    });
    context('when user already has a SaveTokenFarmer', function () {
      it('should mint the cDai and store it in the user\'s SaveTokenFarmer', async () => {
        // mint saveDAI tokens
        await helpers.mint(amount, { from: userWallet });

        const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
        saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

        const cDAIbalance = await cDaiInstance.balanceOf(proxyAddress);
        const ocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const saveDaiMinted = await savedaiInstance.balanceOf(userWallet);

        // all token balances should match
        assert.equal(cDAIbalance.toString(), amount);
        assert.equal(ocDAIbalance.toString(), amount);
        assert.equal(saveDaiMinted.toString(), amount);

        // mint more saveDAI tokens
        await helpers.mint(amount, { from: userWallet });

        const finalcDAIbalance = await cDaiInstance.balanceOf(proxyAddress);
        const finalocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const finalsaveDaiMinted = await savedaiInstance.balanceOf(userWallet);

        // all token balances should match
        assert.equal(finalcDAIbalance.toString(), newAmount);
        assert.equal(finalocDAIbalance.toString(), newAmount);
        assert.equal(finalsaveDaiMinted.toString(), newAmount);
      });
    });

  });

  describe('transfer', async () => {
    it('should revert if the cDai transfer fails', async () => {
      // mint saveDAI tokens
      await helpers.mint(amount, { from: userWallet });

      const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
      saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

      await expectRevert(saveDaiProxy.transfer(recipient, newAmount, { from: userWallet }),
        'The transfer must execute successfully');
    });
    it('should transfer the correct amount of cDai', async () => {
      const balance = await cDaiInstance.balanceOf(recipient);
      // mint saveDAI tokens
      await helpers.mint(amount, { from: userWallet });

      const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
      saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

      const initialProxyBalance = await cDaiInstance.balanceOf(proxyAddress);
      const initialRecipientBalance = await cDaiInstance.balanceOf(recipient);

      assert.equal(initialProxyBalance.toString(), amount);

      await saveDaiProxy.transfer(recipient, amount, { from: userWallet });

      const finalProxyBalance = await cDaiInstance.balanceOf(proxyAddress);
      const finalReceiverBalance = await cDaiInstance.balanceOf(recipient);

      const diff = initialProxyBalance.sub(finalProxyBalance);
      const diff2 = finalReceiverBalance.sub(balance);

      assert.equal(diff.toString(), amount);
      assert.equal(diff2.toString(), amount);
    });
	  it('should return true if the transfer is successful', async () => {
      // mint saveDAI tokens
      await helpers.mint(amount, { from: userWallet });

      const proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
      saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);

      const bool = await saveDaiProxy.transfer.call(recipient, amount, { from: userWallet });
      assert.isTrue(bool);
	  });
  });
});
