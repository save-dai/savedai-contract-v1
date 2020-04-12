pragma solidity ^0.5.0;

// opyn interface
interface OTokenInterface {
    function hasExpired() external view returns (bool);
    function exercise(uint256 _amount, address payable[] memory vaultsToExerciseFrom) external payable;
    function isExerciseWindow() external view returns (bool);
    function getVaultOwners() public view returns (address payable[] memory);
    function hasVault(address payable owner) public view returns (bool);
    function numVaults() public view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function oTokenExchangeRate() external returns (uint256, int32);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function underlyingRequiredToExercise(uint256 oTokensToExercise) public view returns (uint256);
}