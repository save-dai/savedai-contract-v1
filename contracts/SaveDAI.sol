// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "rewards-farmer/contracts/FarmerFactory.sol";
import "./lib/UniswapExchangeInterface.sol";
import "./lib/UniswapFactoryInterface.sol";
import "./lib/CTokenInterface.sol";
import "./lib/OTokenInterface.sol";
import "./lib/ISaveDAI.sol";

contract SaveDAI is ISaveDAI, ERC20, Pausable, AccessControl {
    using SafeMath for uint256;

    /***************
    GLOBAL CONSTANTS
    ***************/
    // Variable to set distant deadline for Uniswap tokenToTokenSwap transactions
    uint256 constant LARGE_BLOCK_SIZE = 1099511627776;

    // Variable used to set near infinite approval allowances
    uint256 constant LARGE_APPROVAL_NUMBER = uint256(-1);

    // interfaces
    UniswapFactoryInterface public uniswapFactory;
    UniswapExchangeInterface public daiUniswapExchange;
    UniswapExchangeInterface public ocDaiExchange;
    CTokenInterface public cDai;
    OTokenInterface public ocDai;
    IERC20 public dai;

    /***************
    EVENTS
    ***************/
    event Mint(uint256 _amount, address _recipient);
    event ExerciseInsurance(uint256 _amount, uint256 _EthReturned, address _user);
    event ExchangeRate(uint256 _exchangeRateCurrent);
    event WithdrawForAssetandOTokens(address _user, uint256 _amount);
    event WithdrawForAsset(address _user, uint256 _amount);
    event WithdrawForUnderlyingAsset(address _user, uint256 _amount);

    constructor(
        address uniswapFactoryAddress,
        address cDaiAddress,
        address ocDaiAddress,
        address daiAddress
    ) 
    ERC20("saveDAI_20210210", "saveDAI")
        public
    {
        cDai = CTokenInterface(cDaiAddress);
        ocDai = OTokenInterface(ocDaiAddress);
        dai = IERC20(daiAddress);
        uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        daiUniswapExchange = _getExchange(daiAddress);
        ocDaiExchange = _getExchange(ocDaiAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(
            dai.approve(address(daiUniswapExchange), LARGE_APPROVAL_NUMBER) &&
            dai.approve(address(cDai), LARGE_APPROVAL_NUMBER)
        );
    }

    /**
    * @notice This function mints saveDAI tokens
    * @param _amount The number of saveDAI to mint
    * @return Returns true if executed successfully
    */
    function mint(uint256 _amount)
        external
        override
        whenNotPaused
        returns (bool)
    {
        // calculate DAI needed to mint _amount of cDAI and mint tokens
        uint256 assetCost = _getCostofAsset(_amount);

        // calculate DAI needed to buy _amount of ocDAI tokens
        uint256 oTokenCost = getCostOfOToken(_amount);

        // transfer total DAI needed
        require(
            dai.transferFrom(
                msg.sender,
                address(this),
                (assetCost.add(oTokenCost))
            )
        );

        uint256 assetAmount = _mintCDai(assetCost);
        uint256 oTokenAmount = _uniswapBuyOCDai(oTokenCost);

        require(assetAmount == _amount, "cDAI minted must equal _amount");
        require(oTokenAmount == _amount, "oTokens purchased must equal _amount");

        super._mint(msg.sender, _amount);

        emit Mint(_amount, msg.sender);

        return true;
    }

    /**
     * @notice Called by anyone holding saveDAI tokens who wants to excercise the underlying
     * ocDAI insurance. The caller transfers their saveDAI tokens and get paid out in ETH.
     * @param _amount the number of saveDAI tokens on which to exercise insurance
     * @param vaultsToExerciseFrom the array of vaults to exercise from.
     */
    function exerciseInsurance(
        uint256 _amount,
        address payable[] calldata vaultsToExerciseFrom)
        external
        override
    {
        // approve ocDai contract to spend both ocDai and cDai
        require(ocDai.approve(address(ocDai), _amount));
        require(cDai.approve(address(ocDai), _amount));

        address payable saveDai = address(this);
        uint256 balanceBefore = saveDai.balance;

        ocDai.exercise(_amount, vaultsToExerciseFrom);

        uint256 balanceAfter = saveDai.balance;
        uint256 EthReturned = balanceAfter.sub(balanceBefore);
        address payable caller = msg.sender;
        caller.transfer(EthReturned);
        super._burn(caller, _amount);

        emit ExerciseInsurance(_amount, EthReturned, caller);
    }

    /**
    * @notice This function will unbundle your saveDAI and transfer ocDAI and cDAI to msg.sender
    * @param _amount The amount of saveDAI tokens to unbundle
    */
    function withdrawForAssetandOTokens(uint256 _amount)
        external
        override
    {
        if (!ocDai.hasExpired()) {
            // transfer _amount of ocDAI to msg.sender
            require(ocDai.transfer(msg.sender, _amount));
        }

        // transfer _amount of cDAI to msg.sender
        require(cDai.transfer(msg.sender, _amount));

        // burn _amount of saveDAI tokens
        _burn(msg.sender, _amount);
        emit WithdrawForAssetandOTokens(msg.sender, _amount);
    }

    /**
    * @notice This function will remove insurance and exchange your saveDAI for cDAI
    * @param _amount The amount of saveDAI tokens to unbundle
    */
    function withdrawForAsset(uint256 _amount)
        external
        override
    {
        require(!ocDai.hasExpired(), "ocDAI must not have expired");
        // swap _amount of ocDAI on Uniswap for DAI
        uint256 daiTokens = _uniswapBuyDai(_amount);

        // mint cDAI
        uint256 cDAItokens = _mintCDai(daiTokens);

        // transfer the sum of the newly minted cDAI with the original _amount
        require(cDai.transfer(msg.sender, cDAItokens.add(_amount)));
        emit WithdrawForAsset(msg.sender, _amount);
        _burn(msg.sender, _amount);
    }

    /**
    * @notice This function will remove insurance and exchange your saveDAI for DAI
    * @param _amount The amount of saveDAI tokens to unbundle
    */
    function withdrawForUnderlyingAsset(uint256 _amount)
        external
        override
    {
        require(!ocDai.hasExpired(), "ocDAI must not have expired");

        // identify saveDAI contract's DAI balance
        uint256 initiaDaiBalance = dai.balanceOf(address(this));

        // Redeem returns 0 on success
        require(cDai.redeem(_amount) == 0, "redeem function must execute successfully");

        // identify saveDAI contract's updated DAI balance
        uint256 updatedDaiBalance = dai.balanceOf(address(this));

        uint256 daiRedeemed = updatedDaiBalance.sub(initiaDaiBalance);

        // saveDAI gives uniswap exchange allowance to transfer ocDAI tokens
        require(ocDai.approve(address(ocDaiExchange), _amount));

        uint256 daiTokens = _uniswapBuyDai(_amount);

        //transfer DAI to msg.sender
        require(dai.transfer(msg.sender, daiTokens.add(daiRedeemed)));

        emit WithdrawForUnderlyingAsset(msg.sender, _amount);
        _burn(msg.sender, _amount);
    }

    /**
    * @notice This function calculates the premiums to be paid if a buyer wants to
    * buy ocDAI on Uniswap
    * @param _oTokensToBuy The number of ocDAI to buy
    */
    function getCostOfOToken(uint256 _oTokensToBuy) public view returns (uint256) {
        // get the amount of ETH that needs to be paid for _oTokensToBuy.
        uint256 ethToPay = ocDaiExchange.getEthToTokenOutputPrice(
            _oTokensToBuy
        );

        // get the amount of daiTokens that needs to be paid to get the desired ethToPay.
        return daiUniswapExchange.getTokenToEthOutputPrice(ethToPay);
    }

    /**
    * @notice Returns the value in DAI for a given amount of saveDAI provided
    * @param _saveDaiAmount The amount of saveDAI to convert to price in DAI
    * @return The value in DAI
    */
    function saveDaiPriceInDaiCurrent(uint256 _saveDaiAmount) 
        external
        override 
        returns (uint256) 
    {
        uint256 oTokenCost = getCostOfOToken(_saveDaiAmount);
        return _getCostofAsset(_saveDaiAmount).add(oTokenCost);
    }

    /**
     * @notice Allows admin to pause contract
     */
    function pause() external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must be admin");
        _pause();
    }

    /**
     * @notice Allows admin to unpause contract
     */
    function unpause() external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must be admin");
        _unpause();
    }

    /*
    * Internal functions
    */
    function _getCostofAsset(uint256 _amount) internal returns (uint256) {
        // calculate DAI needed to mint _amount of cDAI
        uint256 exchangeRate = cDai.exchangeRateCurrent();
        emit ExchangeRate(exchangeRate);
        return _amount.mul(exchangeRate).add(10**18-1).div(10**18);
    }
 
    /**
    * @notice This function buys ocDAI tokens on uniswap
    * @param _premium The amount in DAI tokens needed to insure _amount tokens in mint function
    */
    function _uniswapBuyOCDai(uint256 _premium) internal returns (uint256) {
        return daiUniswapExchange.tokenToTokenSwapInput (
                _premium, // tokens sold
                1, // min_tokens_bought
                1, // min eth bought
                LARGE_BLOCK_SIZE, // deadline
                address(ocDai) // token address
        );
    }

    /**
    * @notice This function buys DAI on uniswap
    * @param _ocDaiTokens The amount in ocDAI tokens to exchange
    */
    function _uniswapBuyDai(uint256 _ocDaiTokens) internal returns (uint256) {
        // saveDAI gives uniswap exchange allowance to transfer ocDAI tokens
        require(ocDai.approve(address(ocDaiExchange), _ocDaiTokens));

        return ocDaiExchange.tokenToTokenSwapInput (
            _ocDaiTokens, // tokens sold
            1, // min_tokens_bought
            1, // min eth bought
            LARGE_BLOCK_SIZE, // deadline
            address(dai) // token address
        );
    }

    /**
    * @notice This function instantiates an interface for a given exchange's address
    * @param _tokenAddress The token's address
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
    function _mintCDai(uint256 _amount) internal returns (uint256) {
        // identify the current balance of the saveDAI contract
        uint256 initialBalance = cDai.balanceOf(address(this));
        // mint cDai
        cDai.mint(_amount);
        // identify the updated balance of the saveDAI contract
        uint256 updatedBalance = cDai.balanceOf(address(this));
        // return number of cDAI tokens minted
        return updatedBalance.sub(initialBalance);
    }

    receive() external payable {}
}
