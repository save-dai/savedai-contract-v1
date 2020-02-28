
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/UniswapExchangeInterface.sol";
import "./lib/UniswapFactoryInterface.sol";
import "./lib/CTokenInterface.sol";
import "./lib/OTokenInterface.sol";

contract SaveDAI is ERC20, ERC20Detailed {
    // mainnet addresses
    address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ocDaiAddress = 0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33;
    address public cDaiAddress = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public uniswapFactoryAddress = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;

    UniswapFactoryInterface public uniswapFactory;
    CTokenInterface public cDai;
    OTokenInterface public ocDai;
    IERC20 public dai;

    constructor() ERC20Detailed("SaveDAI", "SD", 18)
        public {
          cDai = CTokenInterface(cDaiAddress);
          ocDai = OTokenInterface(ocDaiAddress);
          dai = IERC20(daiAddress);
          uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        }

    function mint(address _to, uint256 _amount) external payable returns (bool) {
        // purchase _amount of ocDai from uniswap (call internal _buy function))
        // _buy(_amount);

        // // getExchangeRate for cDai from compound
        // uint256 cDAIExchangeRate = cDai.exchangeRateCurrent();
        // uint256 _daiAmount = _amount * cDAIExchangeRate;
        // // mint cDai
        // uint cDAIAmount = cDai.mint(_daiAmount);
        // require(cDAIAmount == _amount, "cDai and ocDai amounts must match");

        super._mint(_to, _amount);
        return true;
    }

    function exerciseOCDAI(uint256 _amount) public {
        require(balanceOf(msg.sender) >= _amount, "Must have sufficient balance");
        require(ocDai.isExerciseWindow(), "Must be in exercise window");

        // approve ocDai contract to spend both ocDai and cDai
        ocDai.approve(address(ocDaiAddress), _amount);
        cDai.approve(address(ocDaiAddress), _amount);

        uint256 balanceBefore = address(this).balance;
        // for hackathon just hard code the main vault owner

        // address[] memory vaultOwners = [0x9e68B67660c223B3E0634D851F5DF821E0E17D84];
        ocDai.exercise(_amount);

        uint256 balanceAfter = address(this).balance;
        uint256 deltaEth = balanceAfter.sub(balanceBefore);
        address(msg.sender).transfer(deltaEth);
        super._burn(msg.sender, _amount);
      }


    function _buy(uint256 _amount) external returns (uint256) {
        UniswapExchangeInterface uniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(daiAddress));
        // daiErc20.approve(address(uniswapExchange), _amount * 10);
        // uint256 oTokens = uniswapExchange.tokenToTokenSwapInput (
        //         _amount, // tokens sold
        //         1, // min_tokens_bought
        //         1, // min eth bought
        //         now + 12000, // deadline
        //         address(ocdaiAddress) // token address
        // );
        // return oTokens;
    }
}
