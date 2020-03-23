
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

    uint256 public cDaiCost;
    uint256 public ocDaiCost;

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

    constructor() ERC20Detailed("SaveDAI", "SD", 8)
        public
    {
        cDai = CTokenInterface(cDaiAddress);
        ocDai = OTokenInterface(ocDaiAddress);
        dai = IERC20(daiAddress);
        uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        daiUniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(address(daiAddress)));
    }

    /**
    * @notice This function mints saveDAI tokens
    * @param _amount The number of saveDAI to mint
    */
    function mint(uint256 _amount) external returns (bool) {
        // calculate how much DAI we need to pay for _amount of ocDAI tokens
        uint256 paymentForPremium = premiumToPay(_amount);

        // calculate DAI needed to mint _amount of cDAI
        uint256 exchangeRate = cDai.exchangeRateCurrent();
        uint256 amountInDAI = _amount.mul(exchangeRate).div(10**18);

        // total amount of DAI we need to transfer
        uint256 totalTransfer = paymentForPremium.add(amountInDAI);

        require(dai.balanceOf(msg.sender) >= totalTransfer, "Must have sufficient balance");

        // transfer total DAI needed for ocDAI tokens and cDAI tokens
        dai.transferFrom(
            msg.sender,
            address(this),
            totalTransfer
        );

        uint256 ocDAItokens = _uniswapBuyOCDAI(paymentForPremium);
        require(ocDAItokens == _amount, "ocDAI tokens purchased must equal _amount");

        _mintcDAI(amountInDAI);

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
    * buy ocDAI on Uniswap
    * @param ocDaiTokensToBuy The number of ocDAI to buy
    */
    function premiumToPay(uint256 ocDaiTokensToBuy) public view returns (uint256) {
        UniswapExchangeInterface ocDaiExchange = _instantiateOcDaiExchange();

        // get the amount of ETH that needs to be paid for ocDaiTokensToBuy.
        uint256 ethToPay = ocDaiExchange.getEthToTokenOutputPrice(
            ocDaiTokensToBuy
        );

        // get the amount of daiTokens that needs to be paid to get the desired ethToPay.
        return daiUniswapExchange.getTokenToEthOutputPrice(ethToPay);
    }

    /**
    * @notice Returns the value in DAI for a given amount of saveDAI provided
    * @param _saveDaiAmount The amount of saveDAI to convert to price in DAI
    * @return The value in DAI
    */
    function saveDaiPriceInDaiCurrent(uint256 _saveDaiAmount) public returns (uint256) {
        premiumToPay(_saveDaiAmount).add(_saveDaiAmount);
        _getCostOfcDAI(_saveDaiAmount);
        return cDaiCost.add(ocDaiCost);
    }

    /*
    * Internal functions
    */
    function _getCostOfcDAI(uint256 _saveDaiAmount) internal returns (uint256) {
        // Determine the cost in cDAI given the _saveDaiAmount provided
        cDaiCost = _saveDaiAmount.mul(cDai.exchangeRateStored());
        return cDaiCost;
    }

    /**
    * @notice This function instantiates the interface for the ocDaiExchange 
    * @return Returns the UniswapExchangeInterface for the ocDaiExchange
    */
    function _instantiateOcDaiExchange() internal view returns (UniswapExchangeInterface) {
        UniswapExchangeInterface ocDaiExchange = UniswapExchangeInterface(
            uniswapFactory.getExchange(address(ocDaiAddress))
        );
        return ocDaiExchange;
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
