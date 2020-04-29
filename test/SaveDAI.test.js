const Web3 = require('web3');
const provider = 'http://127.0.0.1:8545';
const web3Provider = new Web3.providers.HttpProvider(provider);
const web3 = new Web3(web3Provider);
const helpers = require('./helpers/helpers.js');

const { expect } = require('chai');

const {
  BN,
  ether,
  time,
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
const userWallet = '0x274d9e726844ab52e351e8f1272e7fc3f58b7e5f';

contract('SaveDAI', function (accounts) {
  // amount of ocDAI, cDAI, saveDAI we want to mint
  amount = '4892167171';
  owner = accounts[0];
  notOwner = accounts[1];

  // Number of seconds to increase to ensure February 21st, 2021 has elapsed
  increaseTime = 26409094;

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
  describe('mint', async function () {
    it('should mint saveDAI tokens', async function () {
      // Calculate how much DAI is needed to approve
      const premium = await savedaiInstance.premiumToPay.call(amount);

      let exchangeRate = await cDaiInstance.exchangeRateStored.call();
      exchangeRate = (exchangeRate.toString()) / 1e18;
      let amountInDAI = amount * exchangeRate;
      amountInDAI = new BN(amountInDAI.toString());

      const totalTransfer = premium.add(amountInDAI);
      largerAmount = totalTransfer.add(new BN(ether('0.1')));

      await daiInstance.approve(savedaiAddress, largerAmount, { from: userWallet });

      // mint saveDAI tokens
      await savedaiInstance.mint(amount, { from: userWallet });

      const ocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
      console.log('ocDAI tokens minted, in saveDAI contract', ocDAIbalance.toString());

      const cDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);
      console.log('cDAI tokens minted, in saveDAI contract', cDAIbalance.toString());

      const saveDaiMinted = await savedaiInstance.balanceOf(userWallet);
      console.log('saveDAI tokens minted, in userWallet', saveDaiMinted.toString());
      // all token balances should match
      assert.equal(cDAIbalance.toString(), saveDaiMinted.toString());
      assert.equal(ocDAIbalance.toString(), saveDaiMinted.toString());

      let underlying = await cDaiInstance.balanceOfUnderlying.call(savedaiAddress);
      underlying = underlying / 1e18;
      console.log('underlying balance of cDAI tokens', underlying.toString());
    });
    it('should use the delta in the balance of cDAI to mint the correct number of saveDAI tokens', async function () {
      // get contract's initial cDAI balance
      const initialcDaiBalance = await cDaiInstance.balanceOf(savedaiAddress);

      // get user's initial saveDAI balance
      const initialSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

      // mint saveDAI tokens first time
      await helpers.mint(amount, { from: userWallet });

      // mint saveDAI tokens second time
      await helpers.mint(amount, { from: userWallet });

      // contract's final cDAI balance
      const finalcDaiBalance = await cDaiInstance.balanceOf(savedaiAddress);

      // get user's final saveDAI balance
      const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);
      // get contract's cDAI delta
      const cDaidelta = finalcDaiBalance - initialcDaiBalance;
      // get user's saveDAI delta
      const saveDaiDelta = finalSaveDaiBalance - initialSaveDaiBalance;

      assert.equal(cDaidelta, saveDaiDelta);
    });
    it('should decrease userWallet DAI balance', async function () {
      const initialBalance = await daiInstance.balanceOf(userWallet);

      // Calculate how much DAI is needed to approve
      const premium = await savedaiInstance.premiumToPay.call(amount);

      await daiInstance.approve(savedaiAddress, initialBalance, { from: userWallet });

      // mint saveDAI tokens
      const transaction = await savedaiInstance.mint(amount, { from: userWallet });
      let exchangeRateTransaction = await transaction.logs[0].args._exchangeRateCurrent;
      exchangeRateTransaction = new BN(exchangeRateTransaction.toString()) / 1e18;

      // calculate how much DAI is spent using value from ExchangeRate event
      let daiFromExchangeRateEvent = exchangeRateTransaction * amount;
      daiFromExchangeRateEvent = new BN(daiFromExchangeRateEvent.toString());

      const daiTotalTransfer = premium.add(daiFromExchangeRateEvent) / 1e18;

      const endingBalance = await daiInstance.balanceOf(userWallet);

      const diff = initialBalance.sub(endingBalance) / 1e18;

      assert.approximately(daiTotalTransfer, diff, 0.00000000001000);
    });
    it('should emit the amount of tokens minted', async function () {
      // calculate amount needed for approval
      const daiNeededForPremium = await savedaiInstance.premiumToPay(amount);
      const dai = ether(amount);
      const totalTransfer = daiNeededForPremium.add(dai);
      // approve saveDAI contract
      await daiInstance.approve(savedaiAddress, totalTransfer, { from: userWallet });
      // mint tokens
      const { logs } = await savedaiInstance.mint(amount, { from: userWallet });
      expectEvent.inLogs(logs, 'Mint');
    });
  });
  describe('premiumToPay', function () {
    it('should return premium to pay for ocDAI tokens', async function () {
      const premium = await savedaiInstance.premiumToPay.call(amount);

      // use exchange directly
      const ethToPay = await ocDaiExchange.getEthToTokenOutputPrice.call(amount);
      const premiumShouldBe = await daiExchange.getTokenToEthOutputPrice.call(ethToPay);

      assert.equal(premium.toString(), premiumShouldBe.toString());
    });
  });
  describe('saveDaiPriceInDaiCurrent', function () {
    it('should first identify the cost of ocDai', async function () {
      let premium = await savedaiInstance.premiumToPay(amount);
      premium = new BN(premium);

      ethAmount = await ocDaiExchange.getEthToTokenOutputPrice(amount);
      const daiAmount = await daiExchange.getTokenToEthOutputPrice(ethAmount);

      assert.equal(premium.toString(), daiAmount.toString());
    });
    it('should then identify the cost of cDai using _getCostOfcDAI', async function () {
      amount -= 1; // account for rounding issue
      const saveDaiPrice = await savedaiInstance.saveDaiPriceInDaiCurrent.call(amount) / 1e18;

      const premium = await savedaiInstance.premiumToPay(amount) / 1e18;

      const cDaiCostFromSaveDAIprice = saveDaiPrice - premium;

      let cDaiCostFromExchangeRate = await cDaiInstance.exchangeRateStored();
      cDaiCostFromExchangeRate = (cDaiCostFromExchangeRate * amount)  / 1e18;

      assert.approximately(cDaiCostFromSaveDAIprice, cDaiCostFromExchangeRate.toString() / 1e18, 0.0001);
    });
    it('should return the value in DAI for a given amount of saveDAI', async function () {
      let transaction = await savedaiInstance.saveDaiPriceInDaiCurrent.call(amount);
      transaction = new BN(transaction);

      amount = new BN(amount);

      let premium = await savedaiInstance.premiumToPay(amount);
      premium = new BN(premium);

      let cDaiCost = transaction.sub(premium);
      cDaiCost = new BN(cDaiCost);

      amountOfDAI = cDaiCost.add(premium);
      assert.equal(amountOfDAI.toString(), transaction.toString());
    });
  });

  context('when ocDAI has NOT expired', function () {
    beforeEach(async function () {
      // Mint SaveDAI tokens
      await helpers.mint(amount);
      saveDai = await savedaiInstance.balanceOf(userWallet);
      saveDai = saveDai.toNumber();
    });
    describe('removeInsurance', function () {
      it('should revert if msg.sender does not have the _amount of saveDAI tokens', async function () {
        await expectRevert(savedaiInstance.removeInsurance(saveDai + 1), 'Must have sufficient balance');
      });
      it('should transfer _amount of ocDAI to msg.sender', async function () {
        // Idenitfy the user's initial ocDAI balance
        const initialBalance = await ocDaiInstance.balanceOf(userWallet);

        // Remove userWallet's insurance
        // unbundle saveDAI and send user back _amount of ocDAI
        await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // Idenitfy the user's ocDAI balance after receiving ocDAI
        const finalUserBalance = await ocDaiInstance.balanceOf(userWallet);

        // Calculate the difference in ocDAI tokens
        const diff = finalUserBalance - initialBalance;

        assert.equal(diff, saveDai);
      });
      it('should transfer _amount of cDAI to msg.sender', async function () {
        // Idenitfy the user's initial cDAI balance
        const initialBalance = await cDaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // unbundle saveDAI and send user back _amount of cDAI
        await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // Idenitfy the user's cDAI balance after receiving cDAI
        const finalUserBalance = await cDaiInstance.balanceOf(userWallet);

        // Calculate the difference in cDAI tokens
        const diff = finalUserBalance - initialBalance;

        assert.equal(diff, saveDai);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and their _amount of insurance removed', async function () {
        // Remove _amount of userWallelt's insurance
        const transaction = await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[4].event;
        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[4].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI insurance coverage was removed
        const insuranceRemovedAmount = await transaction.logs[4].args._amount;
        assert.equal(insuranceRemovedAmount.toString(), saveDai);
      });
      it('should burn _amount of msg.sender\'s saveDAI tokens', async function () {
        // Idenitfy the user's initial saveDAI balance
        const initialSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Remove _amount of userWallelt's insurance
        await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // Idenitfy the user's final saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Calculate the difference in user's saveDAI tokens after removing insurance
        const diff = initialSaveDaiBalance - finalSaveDaiBalance;

        assert.equal(diff, saveDai);
      });
    });

    describe('removeAndSellInsuranceForcDAI', function () {
      it('should revert if msg.sender does not have the _amount of saveDAI tokens', async function () {
        await expectRevert(savedaiInstance.removeAndSellInsuranceForcDAI(saveDai + 1, { from: userWallet }), 'Must have sufficient balance');
      });
      it('should transfer cDAI from saveDAI contract to user', async function () {
        // Identify initial cDAI balances
        const initialcDaiBalanceContract = await cDaiInstance.balanceOf(savedaiAddress);
        const initialcDAIbalanceUser = await cDaiInstance.balanceOf(userWallet);

        // Calculate how much cDAI you will receive from swapping ocDAI
        // 1. swap ocDAI for DAI on uniswap
        const cDaiAmount = saveDai; // cDai amount is the same as saveDai
        const eth = await ocDaiExchange.getTokenToEthInputPrice(cDaiAmount);
        const daiBought = await daiExchange.getEthToTokenInputPrice(eth);

        // 2. calculate how much cDAI will be minted
        const exchangeRate = await cDaiInstance.exchangeRateStored.call();

        // subtract 1 to account for rounding issue when calculating cDai minted
        let cDaiMinted = ((daiBought.toString() * 1e18) / exchangeRate.toString()) - 1;
        cDaiMinted = new BN(cDaiMinted);

        // Remove userWallet's insurance
        await savedaiInstance.removeAndSellInsuranceForcDAI(saveDai, { from: userWallet });

        // Identify final cDAI balance in saveDAI contract
        const finalcDAIbalanceContract = await cDaiInstance.balanceOf(savedaiAddress);

        // Identify final cDAI balance in userWallet
        const finalcDAIbalanceUser = await cDaiInstance.balanceOf(userWallet);

        diffInContract = initialcDaiBalanceContract.sub(finalcDAIbalanceContract).add(cDaiMinted);
        diffInUser = finalcDAIbalanceUser.sub(initialcDAIbalanceUser);

        // console.log('cDaiMinted', cDaiMinted.toString());
        // console.log('initialcDaiBalance', initialcDaiBalance.toString())
        // console.log('initialcDAIbalanceUser', initialcDAIbalanceUser.toString())
        // console.log('finalcDAIbalance', finalcDAIbalance.toString())
        // console.log('finalcDAIbalanceUser', finalcDAIbalanceUser.toString())
        // console.log('diffInContract', diffInContract.toString())
        // console.log('diffInUser', diffInUser.toString())

        assert.equal(diffInContract.toString(), diffInUser.toString());
      });
      it.skip('should deposit new DAI into Compound for more cDAI and transfer the total amount of cDAI', async function () {

        // Calculate how much DAI is needed to approve
        const premium = await savedaiInstance.premiumToPay.call(amount);

        let exchangeRate = await cDaiInstance.exchangeRateCurrent.call();
        exchangeRate = (exchangeRate.toString()) / 1e18;
        let amountInDAI = amount * exchangeRate;
        amountInDAI = new BN(amountInDAI.toString());

        const totalTransfer = premium.add(amountInDAI);
        largerAmount = totalTransfer.add(new BN(ether('0.1')));

        await daiInstance.approve(savedaiAddress, largerAmount, { from: userWallet });

        // mint saveDAI tokens
        await savedaiInstance.mint(amount, { from: userWallet });

        // Idenitfy the user's initialcDaiBalance
        const initialcDaiBalance = await cDaiInstance.balanceOf(userWallet);
        console.log('initialcDaiBalance', initialcDaiBalance.toString());

        // Remove userWallelt's insurance
        await savedaiInstance.removeAndSellInsuranceForcDAI(amount, { from: userWallet });

        const amountOfnewcDAI = (premium / exchangeRate);
        console.log('amountOfnewcDAI', amountOfnewcDAI);

        // Idenitfy the user's finalcDaiBalance
        const finalcDaiBalance = await cDaiInstance.balanceOf(userWallet);
        console.log('finalcDaiBalance', finalcDaiBalance.toString());

        const diff = finalcDaiBalance - initialcDaiBalance;
        console.log('diff', diff.toString());

        const totalcDaiTransfered = amountOfnewcDAI + amount;
        console.log('totalcDaiTransfered', totalcDaiTransfered.toString());

        const deltaInCdaiTransferred = totalcDaiTransfered - diff;
        console.log('deltaInCdaiTransferred', deltaInCdaiTransferred.toString());

        const deltaInDai = (deltaInCdaiTransferred * exchangeRate) / 1e18;
        console.log('deltaInDai', deltaInDai.toString());

        const diffInDai = (diff * exchangeRate) / 1e18;
        console.log('diffInDai', diffInDai.toString());

        // NOTE: Give though to using _getCostOfcDAI in _mintcDAI
        // and capture ExchangeRate event for more precise test

        // The difference in cDAI in value is less than 0.04 DAI given exchange rate variability
        assert.approximately(deltaInDai, diffInDai, 0.039);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and their total balance of insurance removed', async function () {
        const transaction = await savedaiInstance.removeAndSellInsuranceForcDAI(saveDai, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[9].event;
        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[9].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI (insurance) was removed
        const insuranceRemovedAmount = await transaction.logs[9].args._amount;
        assert.equal(insuranceRemovedAmount.toString(), saveDai);
      });
      it('should burn the amount of msg.sender\'s saveDAI tokens', async function () {
        const initialSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // unbundle saveDAI and send user back _amount of cDAI plus newly minted cDAI
        await savedaiInstance.removeAndSellInsuranceForcDAI(saveDai, { from: userWallet });

        // Idenitfy the user's finanl saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Calculate the difference in saveDAI tokens
        const diff = initialSaveDaiBalance - finalSaveDaiBalance;

        assert.equal(diff, saveDai);
      });
    });

    describe('removeAndSellInsuranceForDAI', function () {
      it('should revert if msg.sender does not have the _amount of saveDAI tokens', async function () {
        await expectRevert(savedaiInstance.removeAndSellInsuranceForDAI(saveDai + 1, { from: userWallet }), 'Must have sufficient balance');
      });
      it.skip('should send msg.sender the newly minted DAI', async function () {
        // Idenitfy the user's initialDaiBalance
        const initialDaiBalance = await daiInstance.balanceOf(userWallet) / 1e18;
        console.log('initialDaiBalance', initialDaiBalance.toString());

        //Returns the value in DAI for a given amount of saveDAI
        const saveDaiPrice = await savedaiInstance.saveDaiPriceInDaiCurrent.call(saveDai) / 1e18;

        // Remove userWallelt's insurance
        await savedaiInstance.removeAndSellInsuranceForDAI(saveDai, { from: userWallet });

        // Idenitfy the user's updatedDaiBalance
        const updatedDaiBalance = await daiInstance.balanceOf(userWallet) / 1e18;

        const diff = updatedDaiBalance - initialDaiBalance;

        assert.approximately(saveDaiPrice, diff, .099);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and their total balance of insurance removed', async function () {
        const transaction = await savedaiInstance.removeAndSellInsuranceForDAI(saveDai, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[8].event;
        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[8].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI (insurance) was removed
        const insuranceRemovedAmount = await transaction.logs[8].args._amount;
        assert.equal(insuranceRemovedAmount.toString(), saveDai);
      });
      it('should burn the amount of msg.sender\'s saveDAI tokens', async function () {
        const initialSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // unbundle saveDAI and send user back DAI
        await savedaiInstance.removeAndSellInsuranceForDAI(saveDai, { from: userWallet });

        // Idenitfy the user's finanl saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Calculate the difference in saveDAI tokens
        const diff = initialSaveDaiBalance - finalSaveDaiBalance;

        assert.equal(diff, saveDai);
      });
    });

    describe('exerciseInsurance', function () {
      it('should be able to call exercise using one vault', async function () {
        const amtToExercise = await savedaiInstance.balanceOf(userWallet);
        const vaultArray = ['0x076c95c6cd2eb823acc6347fdf5b3dd9b83511e4'];

        const initialocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const initialcDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);

        const totalSupplyBefore = await ocDaiInstance.totalSupply();

        initialETH = await balance.current(userWallet);

        txReceipt = await savedaiInstance.exerciseInsurance(
          amtToExercise,
          vaultArray,
          { from: userWallet },
        );

        const tx = await web3.eth.getTransaction(txReceipt.tx);
        gasUsed = new BN(txReceipt.receipt.gasUsed);
        gasPrice = new BN(tx.gasPrice);

        const deltaEth = txReceipt.receipt.logs[5].args[1];

        const expectedEndETHBalance = initialETH
          .sub(gasUsed.mul(gasPrice))
          .add(deltaEth);

        // check that the user gets the right amount of ETH back
        finalETH = await balance.current(userWallet);
        assert.equal(expectedEndETHBalance.toString(), finalETH.toString());

        // check the supply of ocDAI tokens has changed
        const totalSupplyAfter = await ocDaiInstance.totalSupply();
        assert.equal(totalSupplyBefore.sub(new BN(amtToExercise)).toString(), totalSupplyAfter.toString());

        // check that cDAI and ocDAI were transferred
        const endingocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const endingcDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);
        assert.equal(initialocDAIbalance.sub(endingocDAIbalance).toString(), amtToExercise.toString());
        assert.equal(initialcDAIbalance.sub(endingcDAIbalance).toString(), amtToExercise.toString());
      });
      it('should be able to call exercise using multiple vaults', async function () {
        const amtToExercise = await savedaiInstance.balanceOf(userWallet);
        const vaultArray = ['0xd89b6d5228672ec03ab5929d625e373b4f1f25f3', '0xcae687969d3a6c4649d114b1c768d5b1deae547b'];

        const initialocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const initialcDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);

        const totalSupplyBefore = await ocDaiInstance.totalSupply();

        initialETH = await balance.current(userWallet);

        txReceipt = await savedaiInstance.exerciseInsurance(
          amtToExercise,
          vaultArray,
          { from: userWallet },
        );

        const tx = await web3.eth.getTransaction(txReceipt.tx);
        gasUsed = new BN(txReceipt.receipt.gasUsed);
        gasPrice = new BN(tx.gasPrice);

        const deltaEth = txReceipt.receipt.logs[5].args[1];

        const expectedEndETHBalance = initialETH
          .sub(gasUsed.mul(gasPrice))
          .add(deltaEth);

        // check that the user gets the right amount of ETH back
        finalETH = await balance.current(userWallet);
        assert.equal(expectedEndETHBalance.toString(), finalETH.toString());

        // check the supply of ocDAI tokens has changed
        const totalSupplyAfter = await ocDaiInstance.totalSupply();
        assert.equal(totalSupplyBefore.sub(new BN(amtToExercise)).toString(), totalSupplyAfter.toString());

        // check that cDAI and ocDAI were transferred
        const endingocDAIbalance = await ocDaiInstance.balanceOf(savedaiAddress);
        const endingcDAIbalance = await cDaiInstance.balanceOf(savedaiAddress);
        assert.equal(initialocDAIbalance.sub(endingocDAIbalance).toString(), amtToExercise.toString());
        assert.equal(initialcDAIbalance.sub(endingcDAIbalance).toString(), amtToExercise.toString());
      });
      it('should emit the amount of insurance to exercise', async function () {
        const amtToExercise = await savedaiInstance.balanceOf(userWallet);
        const vaultArray = ['0x076c95c6cd2eb823acc6347fdf5b3dd9b83511e4'];

        txReceipt = await savedaiInstance.exerciseInsurance(
          amtToExercise,
          vaultArray,
          { from: userWallet },
        );

        // check that the right events were emitted
        expectEvent(txReceipt, 'ExerciseInsurance');
      });
      it('should revert if user does not have sufficient balance', async function () {
        // use larger number for amtToExercise
        let amtToExercise = await savedaiInstance.balanceOf(userWallet);
        amtToExercise = amtToExercise.add(new BN(100));
        const vaultArray = ['0x076c95c6cd2eb823acc6347fdf5b3dd9b83511e4'];

        await expectRevert(
          savedaiInstance.exerciseInsurance(
            amtToExercise,
            vaultArray,
            { from: userWallet },
          ),
          'Must have sufficient balance',
        );
      });
    });
  });

  context('when ocDAI has expired', function () {
    beforeEach(async function () {
      // Mint SaveDAI tokens
      await helpers.mint(amount);
      saveDai = await savedaiInstance.balanceOf(userWallet);
      saveDai.toNumber();
    });
    describe('removeInsurance', function () {
      it('should revert if msg.sender does not have the _amount of saveDAI tokens', async function () {
        await expectRevert(savedaiInstance.removeInsurance(saveDai + 1), 'Must have sufficient balance');
      });
      it('should transfer _amount of cDAI to msg.sender', async function () {
        // Increase time so ocDAI has expired
        await time.increase(increaseTime);

        // Idenitfy the user's initial cDAI balance
        const initialBalance = await cDaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // if ocDAI has expired, unbundle saveDAI and send user back _amount of cDAI
        await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // Idenitfy the user's cDAI balance after receiving cDAI
        const finalUserBalance = await cDaiInstance.balanceOf(userWallet);

        // Calculate the difference in cDAI tokens
        const diff = finalUserBalance - initialBalance;

        assert.equal(diff, saveDai);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and the amount of insurance removed', async function () {
        // Remove userWallelt's insurance
        // if ocDAI has expired, unbundle saveDAI and send user back _amount of cDAI
        const transaction = await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[1].event;
        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[1].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI token coverage was removed
        const insuranceRemovedAmount = await transaction.logs[1].args._amount;

        assert.equal(insuranceRemovedAmount.toString(), saveDai);
      });
      it('should burn the amount of msg.sender\'s saveDAI tokens', async function () {
        const initialSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // if ocDAI has expired, unbundle saveDAI and send user back _amount of cDAI
        await savedaiInstance.removeInsurance(saveDai, { from: userWallet });

        // Idenitfy the user's finanl saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Calculate the difference in saveDAI tokens
        const diff =  initialSaveDaiBalance - finalSaveDaiBalance;

        assert.equal(diff, saveDai);
      });
    });

    describe('removeAndSellInsuranceForcDAI', function () {
      it('should revert if ocDAI has expired', async function () {
        // Mint SaveDAI tokens
        await helpers.mint(amount);
        saveDai = await savedaiInstance.balanceOf(userWallet);
        saveDai.toNumber();
        await expectRevert(savedaiInstance.removeAndSellInsuranceForcDAI(saveDai, { from: userWallet }), 'ocDAI must not have expired');
      });
    });

    describe('removeAndSellInsuranceForDAI', function () {
      it('should revert if ocDAI has expired', async function () {
        // Mint SaveDAI tokens
        await helpers.mint(amount);
        saveDai = await savedaiInstance.balanceOf(userWallet);
        saveDai.toNumber();
        await expectRevert(savedaiInstance.removeAndSellInsuranceForDAI(saveDai, { from: userWallet }), 'ocDAI must not have expired');
      });
    });

    describe('exerciseInsurance', function () {
      it('should revert', async function () {
        const amtToExercise = await savedaiInstance.balanceOf(userWallet);
        const vaultArray = ['0x076c95c6cd2eb823acc6347fdf5b3dd9b83511e4'];

        await expectRevert(
          savedaiInstance.exerciseInsurance(
            amtToExercise,
            vaultArray,
            { from: userWallet },
          ),
          'Can\'t exercise outside of the exercise window',
        );
      });
    });
  });

  describe('updateTokenName', function () {
    it('should revert if not called by the owner', async function () {
      await expectRevert(savedaiInstance.updateTokenName('newTokenName', { from: notOwner }), 'Ownable: caller is not the owner');
    });
    it('should revert if _newName is empty', async function () {
      await expectRevert(savedaiInstance.updateTokenName('', { from: owner }), 'The _newName argument must not be empty');
    });
    it('should update and return the new ERC20 token name', async function () {
      await savedaiInstance.updateTokenName('newTokenName');
      newTokenName = await savedaiInstance.name();
      assert.strictEqual(newTokenName, 'newTokenName');
    });
    it('should emit both the new and old ERC20 token name', async function () {
      const { logs } = await savedaiInstance.updateTokenName('newTokenName');
      expectEvent.inLogs(logs, 'UpdateTokenName');
    });
  });

  describe('name', function () {
    it('should return the inital token name if updateTokenName has not been called', async function () {
      initialTokenName = await savedaiInstance.name();
      assert.equal(initialTokenName, 'SaveDAI');
    });
    it('should return the new token name if updateTokenName has been called', async function () {
      await savedaiInstance.updateTokenName('newTokenName');
      newTokenName = await savedaiInstance.name();
      assert.strictEqual(newTokenName, 'newTokenName');
    });
  });

});
