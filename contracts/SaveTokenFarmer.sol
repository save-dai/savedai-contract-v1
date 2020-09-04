// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "rewards-farmer/contracts/Farmer.sol";
import "./lib/CTokenInterface.sol";

 /// @dev The SaveTokenFarmer contract inherits from the base Farmer contract and
 /// is extended to support necessary functionality associated with rewards and governance tokens.
contract SaveTokenFarmer is Farmer {
    using SafeMath for uint256;

    // interfaces
    IERC20 public dai;
    CTokenInterface public cDai;
    IERC20 public comp;

    /// @dev Initializer function to launch proxy.
    /// @param owner The address that will be the owner of the SaveTokenFarmer.
    /// @param cDaiAddress The address of the cDAI asset token.
    /// @param daiAddress The address of the underlying DAI token.
    /// @param compAddress The address of the rewards / governance token.
    function initialize(
        address owner,
        address cDaiAddress,
        address daiAddress,
        address compAddress)
        public
    {
        Farmer.initialize(owner);
        cDai = CTokenInterface(cDaiAddress);
        dai = IERC20(daiAddress);
        comp = IERC20(compAddress);
    }
}
