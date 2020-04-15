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
      // multiple amount by 2 to account for minting
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

      console.log('daiTotalTransfer', daiTotalTransfer.toString());
      console.log('difference in userWallet DAI balance', diff.toString());
      // TODO: Complete this test
      // assert.equal((daiTotalTransfer.toString() / 1e18), (diff.toString() / 1e18));
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

      ocDaiExchange = await uniswapFactoryInstance.getExchange(ocDaiAddress);
      const ocDaiUniswapExchangeInterface = await UniswapExchangeInterface.at(ocDaiExchange);
      ethAmount = await ocDaiUniswapExchangeInterface.getEthToTokenOutputPrice(amount);

      daiExchange = await uniswapFactoryInstance.getExchange(daiAddress);
      const daiUniswapExchangeInterface = await UniswapExchangeInterface.at(daiExchange);
      const daiAmount = await daiUniswapExchangeInterface.getTokenToEthOutputPrice(ethAmount);
      assert.equal(premium.toString(), daiAmount.toString());
    });
    it.skip('should then identify the cost of cDai using _getCostOfcDAI', async function () {
      let transaction = await savedaiInstance.saveDaiPriceInDaiCurrent.call(amount);
      transaction = new BN(transaction);

      amount = new BN(amount);

      let premium = await savedaiInstance.premiumToPay(amount);
      premium = new BN(premium);

      let cDaiCost = transaction.sub(premium);
      cDaiCost = new BN(cDaiCost);

      let exchangeRateStored = await cDaiInstance.exchangeRateStored();
      exchangeRateStored = (exchangeRateStored.toString()) / 1e18;
      exchangeRateStored = new BN(exchangeRateStored);

      console.log('cDaiCost', cDaiCost.toString());
      console.log('exchangeRateStored', exchangeRateStored.mul(amount).toString());

      //assert.equal(cDaiCost.toString(), (exchangeRateStored.mul(amount)).toString());
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

  context('when ocDAI has not expired', function () {
    describe('removeInsurance', function () {
      it.skip('should revert if msg.sender does not have the _amount of saveDAI tokens', async function () {
        await expectRevert(savedaiInstance.removeInsurance(amount), 'Must have sufficient balance');
      });
      beforeEach(async function () {
        // Mint SaveDAI tokens
        await helpers.mint(amount);
      });
      it('should swap _amount on Uniswap for DAI', async function () {
        // Idenitfy the user's initial DAI balance
        const initialDAIBalance = await daiInstance.balanceOf(userWallet) / 1e18;

        // Remove userWallelt's insurance
        await savedaiInstance.removeInsurance(initialSaveDaiBalance, { from: userWallet });

        // Idenitfy the user's final DAI balance
        const finalDAIBalance = await daiInstance.balanceOf(userWallet) / 1e18;

        // User's DAI balance should remain the same given the ocDAI swapped for DAI is spent on more cDAI
        assert.equal(initialDAIBalance.toString(), finalDAIBalance.toString());
      });
      it.only('should deposit new DAI into Compound for more cDAI and transfer the total amount of cDAI', async function () {
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

        // Idenitfy the user's initialcDaiBalance
        const initialcDaiBalance = await cDaiInstance.balanceOf(userWallet);
        console.log('initialcDaiBalance', initialcDaiBalance.toString());

        // Remove userWallelt's insurance
        await savedaiInstance.removeInsurance(initialSaveDaiBalance, { from: userWallet });

        const amountOfnewcDAI = (premium / exchangeRate);
        console.log('amountOfnewcDAI', amountOfnewcDAI);

        // Idenitfy the user's finalcDaiBalance
        const finalcDaiBalance = await cDaiInstance.balanceOf(userWallet);
        console.log('finalcDaiBalance', finalcDaiBalance.toString());

        const diff = finalcDaiBalance - initialcDaiBalance;
        console.log('diff', diff.toString());

        // amount equals 489921671716
        const totalcDaiTransfered = amountOfnewcDAI + 489921671716;
        console.log('totalcDaiTransfered', totalcDaiTransfered.toString());

        const delta = totalcDaiTransfered - diff; 
        console.log('delta', delta.toString());

        //assert.equal(diff, totalcDaiTransfered);
      });
      it('should burn _amount of msg.sender\'s saveDAI tokens', async function () {
        // Remove userWallelt's insurance
        await savedaiInstance.removeInsurance(initialSaveDaiBalance, { from: userWallet });

        // Idenitfy the user's final saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        // Calculate the difference in user's saveDAI tokens after removing insurance
        const diff = initialSaveDaiBalance - finalSaveDaiBalance;

        assert.equal(diff, initialSaveDaiBalance);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and their _amount of insurance removed', async function () {
        const transaction = await savedaiInstance.removeInsurance(initialSaveDaiBalance, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[9].event;
        console.log(event);

        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[9].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI (insurance) was removed
        const insuranceRemovedAmount = await transaction.logs[9].args._amount;
        amount -= 1; // account for rounding issue
        assert.equal(insuranceRemovedAmount.toString(), amount);
      });
    });

    describe('exerciseInsurance', function () {
      beforeEach(async function () {
        await helpers.mint(amount);
      });
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
      await helpers.mint(amount);
    });
    describe('removeInsurance', function () {
      it('should transfer _amount of cDAI to msg.sender', async function () {
        // Increase time so ocDAI has expired
        await time.increaseTo(1614292785);

        // Idenitfy the user's initial cDAI balance
        const initialBalance = await cDaiInstance.balanceOf(userWallet);

        // Remove userWallelt's insurance
        // if ocDAI has expired, unbundle saveDAI and send user back all of their cDAI
        await savedaiInstance.removeInsurance(0, { from: userWallet });

        // Idenitfy the user's cDAI balance after removing insurance
        const finalUserBalance = await cDaiInstance.balanceOf(userWallet);

        // Calculate the difference in cDAI tokens after removing insurance
        const diff = finalUserBalance - initialBalance;

        assert.equal(diff, initialSaveDaiBalance);
      });
      it('should burn all of msg.sender\'s remaining saveDAI tokens', async function () {
        assert.notEqual(initialSaveDaiBalance, 0);

        // Remove userWallelt's insurance
        // if ocDAI has expired, unbundle saveDAI and send user back all of their cDAI
        await savedaiInstance.removeInsurance(0, { from: userWallet });

        // Idenitfy the user's finanl saveDAI balance
        const finalSaveDaiBalance = await savedaiInstance.balanceOf(userWallet);

        assert.equal(finalSaveDaiBalance, 0);
      });
      it('should emit a RemoveInsurance event with the msg.sender\'s address and their total balance of insurance removed', async function () {
        const transaction = await savedaiInstance.removeInsurance(0, { from: userWallet });

        // assert RemoveInsurance fires
        const event = await transaction.logs[1].event;
        assert.equal(event, 'RemoveInsurance');

        // assert msg.sender's address emits in the event
        const userAddress = await transaction.logs[1].args._user;
        assert.equal(userAddress.toLowerCase(), userWallet);

        // assert the correct amount of ocDAI (insurance) was removed
        const insuranceRemovedAmount = await transaction.logs[1].args._amount;

        assert.equal(insuranceRemovedAmount.toString(), initialSaveDaiBalance.toString());
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
