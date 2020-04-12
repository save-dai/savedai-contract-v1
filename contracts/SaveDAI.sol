
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./lib/UniswapExchangeInterface.sol";
import "./lib/UniswapFactoryInterface.sol";
import "./lib/CTokenInterface.sol";
import "./lib/OTokenInterface.sol";

contract SaveDAI is ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;

    /***************
    GLOBAL CONSTANTS
    ***************/
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

    // Will override the private _name variable in ERC20Detailed if token _name is updated
    string private _name;

    /***************
    EVENTS
    ***************/
    event Mint(uint256 _amount, address _recipient);
    event ExerciseInsurance(uint256 _amount, uint256 deltaEth);
    event UpdateTokenName(string _oldName, string _newName);
    event ExchangeRate(uint256 _exchangeRateCurrent);
    event RemoveInsurance(uint256 _amount);

    constructor() ERC20Detailed("SaveDAI", "SD", 8)
        public
    {
        cDai = CTokenInterface(cDaiAddress);
        ocDai = OTokenInterface(ocDaiAddress);
        dai = IERC20(daiAddress);
        uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        daiUniswapExchange = _getExchange(daiAddress);
    }

    /**
    * @notice Will update the token name
    * @param _newName The new name for the token
    * @return Returns the new token name
    */
    function updateTokenName(string memory _newName)
        public
        onlyOwner
    {
        require(bytes(_newName).length > 0, 'The _newName argument must not be empty');
        emit UpdateTokenName(name(), _newName);
        _name = _newName;
    }

    /**
    * @notice Used to override name() in ERC20Detailed if updateTokenName has been called
    * @return Returns the new token name
    */
    function name()
        public
        view
        returns (string memory)
    {
        if (bytes(_name).length == 0) {
            return super.name();
        }
        else {
            return _name;
        }
    }

    /**
    * @notice This function mints saveDAI tokens
    * @param _amount The number of saveDAI to mint
    */
    function mint(uint256 _amount) external returns (bool) {
        // calculate DAI needed to mint _amount of cDAI and mint tokens
        uint256 amountInDAI = _getCostOfcDAI(_amount);

        require(dai.balanceOf(msg.sender) >= amountInDAI, "Must have sufficient balance");

        // transfer DAI needed for cDAI tokens
        dai.transferFrom(
            msg.sender,
            address(this),
            amountInDAI
        );
        uint256 cDAItokens = _mintcDAI(amountInDAI);

        // calculate how much DAI we need to pay to insure amount of cDAItokens
        uint256 paymentForPremium = premiumToPay(cDAItokens);

        require(dai.balanceOf(msg.sender) >= paymentForPremium, "Must have sufficient balance");

        // transfer DAI needed for premium for ocDAI tokens
        dai.transferFrom(
            msg.sender,
            address(this),
            paymentForPremium
        );

        uint256 ocDAItokens = _uniswapBuyOCDAI(paymentForPremium);
        require(ocDAItokens == cDAItokens, "ocDAI tokens purchased must equal amount of cDAItokens minted");

        super._mint(msg.sender, ocDAItokens);

        uint256 amount = ocDAItokens;
        emit Mint(amount, msg.sender);

        return true;
    }

    /**
    * @notice This function calculates the premiums to be paid if a buyer wants to
    * buy ocDAI on Uniswap
    * @param _ocDaiTokensToBuy The number of ocDAI to buy
    */
    function premiumToPay(uint256 _ocDaiTokensToBuy) public view returns (uint256) {
        UniswapExchangeInterface ocDaiExchange = _getExchange(ocDaiAddress);

        // get the amount of ETH that needs to be paid for _ocDaiTokensToBuy.
        uint256 ethToPay = ocDaiExchange.getEthToTokenOutputPrice(
            _ocDaiTokensToBuy
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
        uint256 ocDaiCost = premiumToPay(_saveDaiAmount);
        return _getCostOfcDAI(_saveDaiAmount).add(ocDaiCost);
    }

    /**
     * @notice Called by anyone holding saveDAI tokens who wants to excercise the underlying
     * ocDAI insurance. The caller transfers their saveDAI tokens and get paid out in ETH.
     * @param _amount the number of saveDAI tokens
     * @param vaultsToExerciseFrom the array of vaults to exercise from.
     */
    function exerciseInsurance(uint256 _amount, address payable[] memory vaultsToExerciseFrom) public {
        require(balanceOf(msg.sender) >= _amount, "Must have sufficient balance");

        // approve ocDai contract to spend both ocDai and cDai
        ocDai.approve(address(ocDaiAddress), LARGE_APPROVAL_NUMBER);
        cDai.approve(address(ocDaiAddress), LARGE_APPROVAL_NUMBER);

        uint256 balanceBefore = address(this).balance;

        ocDai.exercise(_amount, vaultsToExerciseFrom);

        uint256 balanceAfter = address(this).balance;
        uint256 deltaEth = balanceAfter.sub(balanceBefore);
        address(msg.sender).transfer(deltaEth);
        super._burn(msg.sender, _amount);

        emit ExerciseInsurance(_amount, deltaEth);
    }

    /**
    * @notice This function will remove insurance
    * @param _amount The amount of saveDAI tokens to unbundle
    */
    function removeInsurance(uint256 _amount) public {
        // require(balanceOf(msg.sender) >= _amount, "Must have sufficient balance");
        if (ocDai.hasExpired()) {
            cDai.transferFrom(address(this), msg.sender, _amount);
            _burn(msg.sender, _amount);
        } else {
        // TODO
        }
        emit RemoveInsurance(_amount);
    }

    /*
    * Internal functions
    */
    function _getCostOfcDAI(uint256 _amount) internal returns (uint256) {
        // calculate DAI needed to mint _amount of cDAI
        uint256 exchangeRate = cDai.exchangeRateCurrent();
        emit ExchangeRate(exchangeRate);
        return _amount.mul(exchangeRate).div(10**18);
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
    * @notice This function instantiates an interface for a given exchange's address
    * @param _tokenAddress The token's address
    * @return Returns the exchange interface nterface
    */
    function _getExchange(address _tokenAddress) internal view returns (UniswapExchangeInterface) {
        UniswapExchangeInterface exchange = UniswapExchangeInterface(
            uniswapFactory.getExchange(address(_tokenAddress))
        );
        return exchange;
    }

    /**
    * @notice This function mints cDAI tokens
    * @param _amount The amount of DAI tokens transferred to Compound
    */
    function _mintcDAI(uint256 _amount) internal returns (uint256) {
        // identify the current balance of the saveDAI contract
        uint256 initialBalance = cDai.balanceOf(address(this));
        // saveDAI gives Compound allowance to transfer DAI tokens
        dai.approve(cDaiAddress, LARGE_APPROVAL_NUMBER);
        // mint cDai
        cDai.mint(_amount);
        // identify the updated balance of the saveDAI contract
        uint256 updatedBalance = cDai.balanceOf(address(this));
        // return number of cDAI tokens minted
        return updatedBalance.sub(initialBalance);
    }

    function() external payable {}
}
