const Web3 = require('web3');
const provider = 'http://127.0.0.1:8545';
const web3Provider = new Web3.providers.HttpProvider(provider);
const web3 = new Web3(web3Provider);

const { expect } = require('chai');
const {
  BN,           // Big Number support
  ether,
  balance,
  expectRevert,
  expectEvent,
} = require('@openzeppelin/test-helpers');

const SaveDAI = artifacts.require('SaveDAI');
const CTokenInterface = artifacts.require('CTokenInterface');
const OTokenInterface = artifacts.require('OTokenInterface');
const ERC20 = artifacts.require('ERC20');
const UniswapFactoryInterface = artifacts.require('UniswapFactoryInterface');
const UniswapExchangeInterface = artifacts.require('UniswapExchangeInterface');

// mainnet addresses
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const ocDaiAddress = '0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33';
const cDaiAddress = '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643';
const uniswapFactoryAddress = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95';
const userWallet = '0xfc9362c9aa1e4c7460f1cf49466e385a507dfb2b';

// amount of ocDAI, cDAI, saveDAI
const amount = '489921671716';

contract('SaveDAI', function (accounts) {
  beforeEach(async function () {
    savedai = await SaveDAI.new();
    savedaiAddress = savedai.address;
    savedaiInstance = await SaveDAI.at(savedaiAddress);

    // instantiate mock tokens
    daiInstance = await ERC20.at(daiAddress);
    ocDaiInstance = await OTokenInterface.at(ocDaiAddress);
    cDaiInstance = await CTokenInterface.at(cDaiAddress);
    uniswapFactoryInstance = await UniswapFactoryInterface.at(uniswapFactoryAddress);

    uniswapFactory = await UniswapFactoryInterface.at(uniswapFactoryAddress);

    const ocDaiExchangeAddress = await uniswapFactory.getExchange(ocDaiAddress);
    ocDaiExchange = await UniswapExchangeInterface.at(ocDaiExchangeAddress);
    const daiExchangeAddress = await uniswapFactory.getExchange(daiAddress);
    daiExchange = await UniswapExchangeInterface.at(daiExchangeAddress);

    owner = accounts[0];
    notOwner = accounts[1];

    // Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: userWallet,
      value: ether('1'),
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

  describe('premiumToPay', async function () {
    it('should return premium to pay for ocDAI tokens', async function () {
      const premium = await savedaiInstance.premiumToPay.call(amount);

      // use exchange directly
      const ethToPay = await ocDaiExchange.getEthToTokenOutputPrice.call(amount);
      const premiumShouldBe = await daiExchange.getTokenToEthOutputPrice.call(ethToPay);

      assert.equal(premium.toString(), premiumShouldBe.toString());
    });
  });
    describe('mint', async function () {
      // amount of ocDAI, cDAI, saveDAI
      const amount = '489921671716';
      it('should mint saveDAI tokens', async function () {
        // premium in DAI needed for `amount` of ocDAI
        const premium = await savedaiInstance.premiumToPay.call(amount);

        // amount of DAI needed to mint `amount` of cDAI
        let exchangeRate = await cDaiInstance.exchangeRateStored.call();
        exchangeRate = (exchangeRate.toString()) / 1e18;
        let amountInDAI = amount * exchangeRate;
        amountInDAI= new BN(amountInDAI.toString());

        // calculate total amount of DAI needed for approval
        let totalTransfer = premium.add(amountInDAI);
        totalTransfer = totalTransfer.add(new BN(ether('0.1')));

        // approve saveDAI contract
        await daiInstance.approve(savedaiAddress, totalTransfer, {from: userWallet});

        // mint saveDAI tokens
        await savedaiInstance.mint(amount, {from: userWallet});

        const ocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        assert.equal(amount, ocDAIbalance);
        console.log('ocDAI tokens minted, in saveDAI contract', ocDAIbalance.toString())

        let cDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);
        console.log('cDAI tokens minted, in saveDAI contract', cDAIbalance.toString())

        const saveDaiMinted = await savedaiInstance.balanceOf(userWallet);
        console.log('saveDAI tokens minted, in userWallet', saveDaiMinted.toString())
        assert.equal(amount, saveDaiMinted);

        let underlying = await cDaiInstance.balanceOfUnderlying.call(savedaiAddress);
        underlying = underlying / 1e18;
        console.log('underlying balance of cDAI tokens', underlying.toString())
      });
      it('should decrease userWallet DAI balance', async function () {
        const initialBalance = await daiInstance.balanceOf(userWallet);

        // premium in DAI needed for `amount` of ocDAI
        const premium = await savedaiInstance.premiumToPay.call(amount);

        // amount of DAI needed to mint `amount` of cDAI
        let exchangeRate = await cDaiInstance.exchangeRateStored.call();
        exchangeRate = (exchangeRate.toString()) / 1e18;
        let amountInDAI = amount * exchangeRate;
        amountInDAI= new BN(amountInDAI.toString());

        // calculate total amount of DAI needed for approval
        let totalTransfer = premium.add(amountInDAI);
        largeAmount = totalTransfer.add(new BN(ether('0.1')));

        // approve saveDAI contract
        await daiInstance.approve(savedaiAddress, largeAmount, {from: userWallet});

        // mint saveDAI tokens
        await savedaiInstance.mint(amount, {from: userWallet});

        const endingBalance = await daiInstance.balanceOf(userWallet);

        const diff = initialBalance.sub(endingBalance);
        console.log('totalTransfer', totalTransfer.toString())
        console.log('difference in userWallet DAI balance', diff.toString())
        // assert.equal(totalTransfer.toString(), diff.toString());
      });
  });
      newTokenName = await savedaiInstance.name();
      assert.strictEqual(newTokenName, 'newTokenName');
    });
  });
});
