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
import "./lib/ISaveTokenFarmer.sol";
import "./lib/CTokenInterface.sol";
import "./lib/OTokenInterface.sol";
import "./lib/ISaveDAI.sol";

contract SaveDAI is ISaveDAI, ERC20, Pausable, AccessControl, FarmerFactory {
    using SafeMath for uint256;

    /***************
    GLOBAL CONSTANTS
    ***************/
    // Variable to set distant deadline for Uniswap tokenToTokenSwap transactions
    uint256 constant LARGE_BLOCK_SIZE = 1099511627776;

    // Variable used to set near infinite approval allowances
    uint256 constant LARGE_APPROVAL_NUMBER = uint256(-1);

    // Variable for pauser
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // COMP token address
    address public compToken;

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
        address daiAddress,
        address compTokenAddress,
        address farmerAddress
    ) 
        ERC20("saveDAI_20210210", "saveDAI")
        FarmerFactory(farmerAddress)
        public
    {
        cDai = CTokenInterface(cDaiAddress);
        ocDai = OTokenInterface(ocDaiAddress);
        dai = IERC20(daiAddress);
        compToken = compTokenAddress;
        uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        daiUniswapExchange = _getExchange(daiAddress);
        ocDaiExchange = _getExchange(ocDaiAddress);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupDecimals(8);

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
        address proxy;

        // if msg.sender does not have a proxy, deploy proxy
        if (farmerProxy[msg.sender] == address(0)) {
            proxy = deployProxy(
                msg.sender,
                address(cDai),
                address(dai),
                compToken);
        } else {
            proxy = farmerProxy[msg.sender];
        }

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

        // mint the insurance token
        uint256 oTokenAmount = _uniswapBuyOCDai(oTokenCost);

        // transfer DAI to the user's SaveTokenFarmer to mint cDAI
        require(dai.transfer(proxy, assetCost));

        // mint the interest bearing token
        uint256 assetAmount = ISaveTokenFarmer(proxy).mint();

        require(assetAmount == _amount, "cDAI minted must equal _amount");
        require(oTokenAmount == _amount, "oTokens purchased must equal _amount");

        super._mint(msg.sender, _amount);

        emit Mint(_amount, msg.sender);

        return true;
    }

    /// @dev saveDAI's token transfer function.
    /// @param recipient The address receiving your token.
    /// @param amount The number of tokens to transfer.
    /// @return Returns true if successfully executed.
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool) 
    {
        address senderProxy = farmerProxy[msg.sender];
        address recipientProxy = farmerProxy[recipient];

        // if recipient does not have a proxy, deploy a proxy
        if (recipientProxy == address(0)) {
            recipientProxy = deployProxy(
                recipient,
                address(cDai),
                address(dai),
                compToken);
        } 

        // transfer interest bearing token to recipient
        ISaveTokenFarmer(senderProxy).transfer(recipientProxy, amount);

        // transfer TokenK tokens
        super.transfer(recipient, amount);

        return true;
    }

    /// @dev saveDAI's redeem tokens function.
    /// @param amount The number of tokens to redeem.
    function redeem(uint256 amount) public {
        address proxy = farmerProxy[msg.sender];
        ISaveTokenFarmer(proxy).redeem(amount, msg.sender);
        _burn(msg.sender, amount);
    }

    /**
     * @notice Called by anyone holding saveDAI tokens who wants to excercise the underlying
     * ocDAI insurance. The caller transfers their saveDAI tokens and gets paid out in ETH.
     * @param _amount the number of saveDAI tokens on which to exercise insurance
     * @param vaultsToExerciseFrom the array of vaults to exercise from.
     */
    function exerciseInsurance(
        uint256 _amount,
        address payable[] calldata vaultsToExerciseFrom)
        external
        override
    {
        require(farmerProxy[msg.sender] != address(0), 
            "The user must have a farmer address");

        // get user's SaveTokenFarmer address
        address proxy = farmerProxy[msg.sender];

        // transfer cDAI from SaveTokenFarmer
        require(ISaveTokenFarmer(proxy).transfer(address(this), _amount));

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

        require(farmerProxy[msg.sender] != address(0),
            "The user farmer proxy must exist");

        // get user's SaveTokenFarmer address
        address proxy = farmerProxy[msg.sender];

        // transfer the interest bearing cDAI to msg.sender
        require(ISaveTokenFarmer(proxy).transfer(msg.sender, _amount));

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
        require(farmerProxy[msg.sender] != address(0), 
            "The user must have a farmer address");

        // identify saveDAI contract's cDAI balance
        uint256 initialcDaiBalance = cDai.balanceOf(address(this));

        // swap _amount of ocDAI on Uniswap for DAI
        uint256 daiTokens = _uniswapBuyDai(_amount);

        // mint cDAI - returns 0 when executed successfully
        require(cDai.mint(daiTokens) == 0);

        // identify saveDAI contract's updated cDAI balance
        uint256 updatedcDaiBalance = cDai.balanceOf(address(this));

        // determine amount of cDAI minted
        uint256 cDaiTokens = updatedcDaiBalance.sub(initialcDaiBalance);

        // get the proxy address to transfer cDAI
        address proxy = farmerProxy[msg.sender];

        // transfer cDAI from SaveTokenFarmer
        require(ISaveTokenFarmer(proxy).transfer(address(this), _amount));
        
        // transfer sum of newly minted cDAI with the original _amount in the SaveTokenFarmer
        require(cDai.transfer(msg.sender, cDaiTokens.add(_amount)));
        
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
        require(farmerProxy[msg.sender] != address(0), 
            "The user must have a farmer address");

        // identify saveDAI contract's DAI balance
        uint256 initialDaiBalance = dai.balanceOf(address(this));

        // get the proxy address to redeem cDAI from
        address proxy = farmerProxy[msg.sender];

        // transfer cDAI from SaveTokenFarmer
        require(ISaveTokenFarmer(proxy).redeem(_amount, address(this)));

        // identify saveDAI contract's updated DAI balance
        uint256 updatedDaiBalance = dai.balanceOf(address(this));

        uint256 daiRedeemed = updatedDaiBalance.sub(initialDaiBalance);

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
        require(hasRole(PAUSER_ROLE, msg.sender),
            "Caller must be admin");
        _pause();
    }

    /**
     * @notice Allows admin to unpause contract
     */
    function unpause() external override {
        require(hasRole(PAUSER_ROLE, msg.sender),
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

    receive() external payable {}
}
