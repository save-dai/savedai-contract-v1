const SaveDAI = artifacts.require('SaveDAI');

contract('SaveDAI', function (accounts) {
    beforeEach(async function () {
        saveDAI = await SaveDAI.new();
        saveDAIInstance = await SaveDAI.at(saveDAI.address);
    });

  describe('_buy', function () {
    it('it just should', async function () {
      let address = await saveDAIInstance.daiErc20.call();
      console.log(address);
    });
  });
});
