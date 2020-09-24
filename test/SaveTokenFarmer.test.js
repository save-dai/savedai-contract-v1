const Web3 = require('web3');
const provider = 'http://127.0.0.1:8545';
const web3Provider = new Web3.providers.HttpProvider(provider);
const web3 = new Web3(web3Provider);
const helpers = require('./helpers/helpers.js');

const { expect } = require('chai');

const {
  BN,
  ether,
  balance,
  expectRevert,
} = require('@openzeppelin/test-helpers');

const SaveDAI = artifacts.require('SaveDAI');
const SaveTokenFarmer = artifacts.require('SaveTokenFarmer');
const CTokenInterface = artifacts.require('CTokenInterface');
const OTokenInterface = artifacts.require('OTokenInterface');
const ERC20 = artifacts.require('ERC20');
const UniswapFactoryInterface = artifacts.require('UniswapFactoryInterface');
const UniswapExchangeInterface = artifacts.require('UniswapExchangeInterface');

// mainnet addresses
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const ocDaiAddress = '0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33';
const cDaiAddress = '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643';
const compAddress = '0xc00e94cb662c3520282e6f5717214004a7f26888';
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

    // mint saveDAI tokens
    await helpers.mint(amount, { from: userWallet });

    proxyAddress = await savedaiInstance.farmerProxy.call(userWallet);
    saveDaiProxy = await SaveTokenFarmer.at(proxyAddress);
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
      it('should revert if not called by the SaveDAI contract', async () => {
        await expectRevert(saveDaiProxy.mint({ from: userWallet }),
          'Ownable: caller is not the owner');
      });
      it('should deploy proxy for msg.sender and set them as owner', async () => {
        const owner = await saveDaiProxy.owner();

        assert.equal(owner.toLowerCase(), savedaiAddress.toLowerCase());
      });
      it('should mint the cDai and store it in the user\'s SaveTokenFarmer', async () => {
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

        const cDAIdiff = finalcDAIbalance.sub(cDAIbalance);
        const ocDAIdiff = finalocDAIbalance.sub(ocDAIbalance);
        const saveDAIdiff = finalsaveDaiMinted.sub(saveDaiMinted);

        const cDAIsum = cDAIdiff.add(cDAIbalance);
        const ocDAIsum = ocDAIdiff.add(ocDAIbalance);
        const saveDAIsum = saveDAIdiff.add(saveDaiMinted);

        // all token balances should match
        assert.equal(finalcDAIbalance.toString(), cDAIsum.toString());
        assert.equal(finalocDAIbalance.toString(), ocDAIsum.toString());
        assert.equal(finalsaveDaiMinted.toString(), saveDAIsum.toString());
      });
    });

  });

  describe('transfer', async () => {
    it('should revert if not called by the SaveDAI contract', async () => {
      await expectRevert(saveDaiProxy.transfer(recipient, amount, { from: userWallet }),
        'Ownable: caller is not the owner');
    });
    it('should revert if the cDai transfer fails', async () => {
      await expectRevert(savedaiInstance.transfer(recipient, newAmount, { from: userWallet }),
        'The transfer must execute successfully');
    });
    it('should transfer the correct amount of cDai', async () => {
      const balance = await cDaiInstance.balanceOf(recipient);

      const initialProxyBalance = await cDaiInstance.balanceOf(proxyAddress);
      const initialRecipientBalance = await cDaiInstance.balanceOf(recipient);

      assert.equal(initialProxyBalance.toString(), amount);

      await savedaiInstance.transfer(recipient, amount, { from: userWallet });

      recipientProxyAddress = await savedaiInstance.farmerProxy.call(recipient);

      const finalProxyBalance = await cDaiInstance.balanceOf(proxyAddress);
      const finalReceiverBalance = await cDaiInstance.balanceOf(recipientProxyAddress);

      const diff = initialProxyBalance.sub(finalProxyBalance);
      const diff2 = finalReceiverBalance.sub(balance);

      assert.equal(diff.toString(), amount);
      assert.equal(diff2.toString(), amount);
    });
	  it('should return true if the transfer is successful', async () => {
      const bool = await savedaiInstance.transfer.call(recipient, amount, { from: userWallet });
      assert.isTrue(bool);
	  });
  });

  describe('redeem', async () => {
    it('should revert if not called by the SaveDAI contract', async () => {
      await expectRevert(saveDaiProxy.redeem(amount, userWallet, { from: userWallet }),
        'Ownable: caller is not the owner');
    });
    it('should revert if redemption is unsuccessful', async () => {
      await expectRevert(savedaiInstance.redeem(newAmount, { from: userWallet }),
        'redeem function must execute successfully');
    });
  });
});
