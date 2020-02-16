
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

// Solidity Interface
contract UniswapFactoryInterface {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

contract IERC20Interface {
    function approve(address _spender, uint256 _value) external returns (bool);
}

// compound interface
contract cTokenInterface {
    function mint(uint mintAmount) external returns (uint); // For ERC20
    function exchangeRateCurrent() external returns (uint256);
}

// opyn interface
contract oTokenInterface {
    function exercise(uint256 oTokensToExercise, address payable[] calldata vaultsToExerciseFrom) external payable;
    function isExerciseWindow() external view returns (bool);
}

contract SaveDAI {
    address public OCDAIAddress = 0xd344828e67444f0921822e83d83d009B85B04454;
    address public CDAIAddress = 0xe7bc397DBd069fC7d0109C0636d06888bb50668c;
    // address public uniswapFactoryAddress = 0xd344828e67444f0921822e83d83d009B85B04454;
    address public daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    UniswapFactoryInterface public uniswapFactory;
    cTokenInterface public cDAI;
    oTokenInterface public ocDAI;
    IERC20Interface public IERC20;

    constructor(address _factory)
        public {
        //   uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
          cDAI = cTokenInterface(CDAIAddress);
          ocDAI = oTokenInterface(OCDAIAddress);
          IERC20 = IERC20Interface(daiAddress);
          uniswapFactory = UniswapFactoryInterface(_factory);
        }

    function testCompoundMinting(uint256 _amount) public returns (bool) {
        // getExchangeRate for cDAI from compound
        uint256 cDAIExchangeRate = cDAI.exchangeRateCurrent();
        uint256 _daiAmount = _amount * cDAIExchangeRate;
        // mint cDAI
        uint cDAIAmount = cDAI.mint(_daiAmount);
        require(cDAIAmount == _amount, "cDAI and ocDAI amounts must match");
        return true;
    }

    // function mint(address _to, uint256 _amount) external payable returns (bool) {
    //     // purchase _amount of ocDAI from uniswap (call internal _buy function))
    //     _buy(_amount);

    //     // getExchangeRate for cDAI from compound
    //     uint256 cDAIExchangeRate = cDAI.exchangeRateCurrent();
    //     uint256 _daiAmount = _amount * cDAIExchangeRate;
    //     // mint cDAI
    //     uint cDAIAmount = cDAI.mint(_daiAmount);
    //     require(cDAIAmount == _amount, "cDAI and ocDAI amounts must match");

    //     // super._mint(_to, _amount);
    //     return true;
    // }

    
    function getExchange(address _daiAddress) public view returns (address) {
        return uniswapFactory.getExchange(_daiAddress);
    }
    
    function testExchange() public view returns (UniswapExchangeInterface) {
        UniswapExchangeInterface uniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(daiAddress));
        return uniswapExchange;
    }
    
    function returnTokenAddress() public view returns (address) {
        UniswapExchangeInterface uniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(daiAddress));
        return uniswapExchange.tokenAddress();
    }


    function _buy(uint256 _amount) external returns (uint256) {
        UniswapExchangeInterface uniswapExchange = UniswapExchangeInterface(uniswapFactory.getExchange(daiAddress));
        IERC20.approve(address(uniswapExchange), _amount * 10);
        uint256 oTokens = uniswapExchange.tokenToTokenSwapInput (
                _amount, // tokens sold
                1, // min_tokens_bought
                1, // min eth bought
                now + 12000, // deadline
                address(OCDAIAddress) // token address
        );
        return oTokens;
    }
}
