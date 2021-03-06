// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISaveTokenFarmer {
    function mint() external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function redeem(uint256 amount, address user) external returns (bool);
    function getTotalCOMPEarned() external returns (uint256);
    function withdrawReward(address user) external;
}