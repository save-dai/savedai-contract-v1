pragma solidity ^0.5.0;

interface ISaveDAI {
	function mint(uint256 _amount) external returns (uint256);
	function exerciseInsurance(uint256 _amount, address payable[] calldata vaultsToExerciseFrom) external;
	function withdrawForAssetandOTokens(uint256 _amount) external;
	function withdrawForAsset(uint256 _amount) external;
	function withdrawForUnderlyingAsset(uint256 _amount) external;
	function saveDaiPriceInDaiCurrent(uint256 _saveDaiAmount) external returns (uint256);
}