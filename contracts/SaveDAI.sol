
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/UniswapExchangeInterface.sol";
import "./lib/UniswapFactoryInterface.sol";
import "./lib/CTokenInterface.sol";
import "./lib/OTokenInterface.sol";

contract SaveDAI is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    uint256 constant LARGE_BLOCK_SIZE = 1651753129000;
    uint256 constant LARGE_APPROVAL_NUMBER = 10**30;

    // mainnet addresses
    address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ocDaiAddress = 0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33;
    address public cDaiAddress = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public uniswapFactoryAddress = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;

    UniswapFactoryInterface public uniswapFactory;
    UniswapExchangeInterface public daiUniswapExchange;
    CTokenInterface public cDai;
    OTokenInterface public ocDai;
    IERC20 public dai;

    constructor() ERC20Detailed("SaveDAI", "SD", 18)
        public {
          cDai = CTokenInterface(cDaiAddress);
          ocDai = OTokenInterface(ocDaiAddress);
          dai = IERC20(daiAddress);
          uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
          daiUniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(address(daiAddress)));
        }

    /**
    * @notice This function mints saveDAI tokens
    * @param _amount The number of saveDAI tokens to mint
    */
    function mint(uint256 _amount) external returns (bool) {
        // calculate how much DAI we need to pay for ocDAI premium
        uint256 paymentForPremium = premiumToPay(_amount);

        // precise DAI amount using decimals
        uint256 amount = _amount.mul(10**18);

        // total amount of DAI we need to transfer
        uint256 totalTransfer = paymentForPremium.add(amount);

        // transfer total DAI needed for ocDAI tokens and cDAI tokens
        dai.transferFrom(
            msg.sender,
            address(this),
            totalTransfer
        );

        _uniswapBuyOCDAI(paymentForPremium);
        _mintcDAI(amount);

        super._mint(msg.sender, _amount);
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


    /**
    * @notice This function calculates the premiums to be paid if a buyer wants to
    * buy oTokens on Uniswap
    * @param ocDaiTokensToBuy The number of oTokens to buy
    */
    function premiumToPay(
        uint256 ocDaiTokensToBuy
    ) public view returns (uint256) {

        // get the amount of ETH that needs to be paid for ocDaiTokensToBuy.
        UniswapExchangeInterface ocDaiExchange = UniswapExchangeInterface(
            uniswapFactory.getExchange(address(ocDaiAddress))
        );

        uint256 ethToPay = ocDaiExchange.getEthToTokenOutputPrice(
            ocDaiTokensToBuy
        );

        // get the amount of daiTokens that needs to be paid to get the desired ethToPay.
        return daiUniswapExchange.getTokenToEthOutputPrice(ethToPay);
    }

    /**
    * @notice This function buys ocDAI tokens on uniswap
    * @param _premium The amount in DAI tokens needed to insure _amount tokens in mint function
    */
    function _uniswapBuyOCDAI(uint256 _premium) internal returns (uint256) {

        // saveDAI gives uniswap exchange allowance to transfer DAI tokens
        dai.approve(address(daiUniswapExchange), LARGE_APPROVAL_NUMBER);

        return daiUniswapExchange.tokenToTokenSwapInput (
                _premium, // tokens sold
                1, // min_tokens_bought
                1, // min eth bought
                LARGE_BLOCK_SIZE, // deadline
                address(ocDai) // token address
        );
    }

    /**
    * @notice This function mints cDAI tokens
    * @param _amount The amount of DAI tokens transferred to Compound
    */
    function _mintcDAI(uint256 _amount) internal returns (uint256) {

        // saveDAI gives Compound allowance to transfer DAI tokens
        dai.approve(cDaiAddress, LARGE_APPROVAL_NUMBER);

        // mint cDai
        uint256 cDAIAmount = cDai.mint(_amount);
        return cDAIAmount;
    }

}
