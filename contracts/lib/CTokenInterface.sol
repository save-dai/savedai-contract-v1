pragma solidity ^0.5.0;

// compound interface
interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint256); // For ERC20
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}