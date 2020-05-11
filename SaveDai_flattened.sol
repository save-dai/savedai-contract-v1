
// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: @openzeppelin/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/lib/UniswapExchangeInterface.sol

pragma solidity ^0.5.0;

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

// File: contracts/lib/UniswapFactoryInterface.sol

pragma solidity ^0.5.0;

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

// File: contracts/lib/CTokenInterface.sol

pragma solidity ^0.5.0;

// compound interface
interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint256); // For ERC20
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function redeem(uint redeemTokens) external returns (uint);
}

// File: contracts/lib/OTokenInterface.sol

pragma solidity ^0.5.0;

// opyn interface
interface OTokenInterface {
    function hasExpired() external view returns (bool);
    function exercise(uint256 _amount, address payable[] calldata vaultsToExerciseFrom) external payable;
    function isExerciseWindow() external view returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function oTokenExchangeRate() external returns (uint256, int32);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function underlyingRequiredToExercise(uint256 oTokensToExercise) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// File: contracts/lib/ISaveDAI.sol

pragma solidity ^0.5.0;

interface ISaveDAI {
    function mint(uint256 _amount) external returns (bool);
    function exerciseInsurance(uint256 _amount, address payable[] calldata vaultsToExerciseFrom) external;
    function withdrawForAssetandOTokens(uint256 _amount) external;
    function withdrawForAsset(uint256 _amount) external;
    function withdrawForUnderlyingAsset(uint256 _amount) external;
    function saveDaiPriceInDaiCurrent(uint256 _saveDaiAmount) external returns (uint256);
}

// File: contracts/SaveDAI.sol

pragma solidity ^0.5.0;











contract SaveDAI is ISaveDAI, ERC20, ERC20Detailed, Pausable {
    using SafeMath for uint256;

    /***************
    GLOBAL CONSTANTS
    ***************/
    // Variable to set distant deadline for Uniswap tokenToTokenSwap transactions
    uint256 constant LARGE_BLOCK_SIZE = 1099511627776;

    // Variable used to set near infinite approval allowances
    uint256 constant LARGE_APPROVAL_NUMBER = 10**30;

    // interfaces
    UniswapFactoryInterface public uniswapFactory;
    UniswapExchangeInterface public daiUniswapExchange;
    UniswapExchangeInterface public ocDaiExchange;
    CTokenInterface public cDai;
    OTokenInterface public ocDai;
    IERC20 public dai;

    // Will override the private _name variable in ERC20Detailed if token _name is updated
    string private _name;

    /***************
    EVENTS
    ***************/
    event Mint(uint256 _amount, address _recipient);
    event ExerciseInsurance(uint256 _amount, uint256 _EthReturned, address _user);
    event UpdateTokenName(string _newName);
    event ExchangeRate(uint256 _exchangeRateCurrent);
    event WithdrawForAssetandOTokens(address _user, uint256 _amount);
    event WithdrawForAsset(address _user, uint256 _amount);
    event WithdrawForUnderlyingAsset(address _user, uint256 _amount);

    constructor(
        address uniswapFactoryAddress,
        address cDaiAddress,
        address ocDaiAddress,
        address daiAddress
    ) ERC20Detailed("saveDAI_20210210", "saveDAI", 8)
        public
    {
        cDai = CTokenInterface(cDaiAddress);
        ocDai = OTokenInterface(ocDaiAddress);
        dai = IERC20(daiAddress);
        uniswapFactory = UniswapFactoryInterface(uniswapFactoryAddress);
        daiUniswapExchange = _getExchange(daiAddress);
        ocDaiExchange = _getExchange(ocDaiAddress);

        require(
            dai.approve(address(daiUniswapExchange), LARGE_APPROVAL_NUMBER) &&
            dai.approve(address(cDai), LARGE_APPROVAL_NUMBER)
        );
    }

    /**
    * @notice Will update the token name
    * @return Returns the new token name
    */
    function updateTokenName()
        public
        returns (string memory)
    {
        require(ocDai.hasExpired(), "Token must have expired");
        _name = string(abi.encodePacked(name(), '_expired'));
        emit UpdateTokenName(name());
        return _name;
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
    * @return The number of saveDAI tokens minted
    */
    function mint(uint256 _amount)
        external
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
    {
        // approve ocDai contract to spend both ocDai and cDai
        require(ocDai.approve(address(ocDai), _amount));
        require(cDai.approve(address(ocDai), _amount));

        address payable saveDai = address(this);
        uint256 balanceBefore = saveDai.balance;

        ocDai.exercise(_amount, vaultsToExerciseFrom);

        uint256 balanceAfter = saveDai.balance;
        uint256 EthReturned = balanceAfter.sub(balanceBefore);
        address(msg.sender).transfer(EthReturned);
        super._burn(msg.sender, _amount);

        emit ExerciseInsurance(_amount, EthReturned, msg.sender);
    }

    /**
    * @notice This function will unbundle your saveDAI and transfer ocDAI and cDAI to msg.sender
    * @param _amount The amount of saveDAI tokens to unbundle
    */
    function withdrawForAssetandOTokens(uint256 _amount)
        external
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
    function saveDaiPriceInDaiCurrent(uint256 _saveDaiAmount) external returns (uint256) {
        uint256 oTokenCost = getCostOfOToken(_saveDaiAmount);
        return _getCostofAsset(_saveDaiAmount).add(oTokenCost);
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

    function() external payable {}
}
