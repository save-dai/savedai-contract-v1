pragma solidity ^0.5.0;

// compound interface
contract CTokenInterface {
    function mint(uint mintAmount) external returns (uint256); // For ERC20
    function exchangeRateCurrent() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}