const { encodeCall } = require('@openzeppelin/upgrades');

// mainnet addresses
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const cDaiAddress = '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643';
const compAddress = '0xc00e94cb662c3520282e6f5717214004a7f26888';
const userWallet = '0x897607ab556177b0e0938541073ac1e01c55e483';

const {
  BN,           // Big Number support
  ether,
} = require('@openzeppelin/test-helpers');

// mint SaveDAI tokens
async function mint (_amount) {
  // Calculate how much DAI is needed to approve
  const premium = await savedaiInstance.getCostOfOToken.call(_amount);

  let exchangeRate = await cDaiInstance.exchangeRateStored.call();
  exchangeRate = (exchangeRate.toString()) / 1e18;
  let amountInDAI = _amount * exchangeRate;
  amountInDAI = new BN(amountInDAI.toString());

  const totalTransfer = premium.add(amountInDAI);
  largerAmount = totalTransfer.add(new BN(ether('0.1')));

  await daiInstance.approve(savedaiAddress, largerAmount, { from: userWallet });

  // mint saveDAI tokens
  await savedaiInstance.mint(_amount, { from: userWallet });
}

module.exports = {
  mint,
};
