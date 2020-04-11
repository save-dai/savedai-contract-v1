pragma solidity ^0.5.0;

// opyn interface
interface OTokenInterface {
    function hasExpired() external view returns (bool);
    function exercise(uint256 oTokensToExercise) external payable;
    function isExerciseWindow() external view returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function oTokenExchangeRate() external returns (uint256, int32);
    function balanceOf(address account) external view returns (uint256);
}