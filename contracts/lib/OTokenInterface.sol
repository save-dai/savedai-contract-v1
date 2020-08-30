// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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