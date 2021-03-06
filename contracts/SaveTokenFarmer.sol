// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "rewards-farmer/contracts/Farmer.sol";
import "./lib/ISaveTokenFarmer.sol";
import "./lib/CTokenInterface.sol";
import "./lib/IComptrollerLens.sol";

 /// @dev The SaveTokenFarmer contract inherits from the base Farmer contract and
 /// is extended to support necessary functionality associated with rewards and governance tokens.
contract SaveTokenFarmer is ISaveTokenFarmer, Farmer {
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

    /// @dev Mint the cDAI asset token that sits in the contract and accrues interest as
    /// well as the corresponding governance / rewards tokens, COMP in this case.
    /// @return The amount of cDAI minted.
    function mint() 
        external 
        override 
        onlyOwner 
        returns (uint256) 
    {
        // identify the current balance of the contract
        uint256 daiBalance = dai.balanceOf(address(this));

        // approve the transfer
        dai.approve(address(cDai), daiBalance);

        // mints cDAI tokens and returns the amount minted
        return _mintCDai(daiBalance);
    }

    /// @dev Transfer the cDAI asset token.
    /// @param to The address the cDAI should be transferred to.
    /// @param amount The amount of cDAI to transfer.
    /// @return Returns true if succesfully executed.
    function transfer(address to, uint256 amount) 
        external 
        override 
        onlyOwner 
        returns (bool) 
    {
        require(cDai.transfer(to, amount), 
            "The transfer must execute successfully");
        return true;
    }

    /// @dev Redeems the cDAI asset token for DAI and withdraws
    /// the rewards / governance tokens that have accrued.
    /// @param amount The amount of cDAI to redeem.
    /// @param user The address to send the DAI to.
    /// @return Returns true if succesfully executed.
    function redeem(uint256 amount, address user) 
        external 
        override 
        onlyOwner 
        returns (bool) 
    {
        // identify SaveTokenFarmer contract's DAI balance
        uint256 initialDaiBalance = dai.balanceOf(address(this));

        // Redeem returns 0 on success
        require(cDai.redeem(amount) == 0, "redeem function must execute successfully");

         // identify SaveTokenFarmer contract's updated DAI balance
        uint256 updatedDaiBalance = dai.balanceOf(address(this));

        uint256 daiRedeemed = updatedDaiBalance.sub(initialDaiBalance);

        require(dai.transfer(user, daiRedeemed), "must transfer");

        // withdraw reward
        withdrawReward(user);

        return true;
    }

    /// @dev Returns the COMP balance that has accured in the contract.
    /// @return Returns the balance of COMP in the contract.
    function getTotalCOMPEarned() 
        external
        override
        onlyOwner 
        returns (uint256) 
    {
        IComptrollerLens comptroller = IComptrollerLens(address(cDai.comptroller()));
        comptroller.claimComp(address(this));

        uint256 balance = comp.balanceOf(address(this));
        return balance;
    }

    /// @dev Allows user to withdraw the accrued COMP tokens at any time.
    /// @param user The address to send the COMP tokens to.
    function withdrawReward(address user) 
        public
        override
        onlyOwner
    {
        IComptrollerLens comptroller = IComptrollerLens(address(cDai.comptroller()));
        comptroller.claimComp(address(this));

        uint256 balance = comp.balanceOf(address(this));
        require(comp.transfer(user, balance), "must transfer");
    }

    /***************
    INTERNAL FUNCTIONS
    ***************/

    /// @notice This function mints cDAI tokens
    /// @param _amount The amount of DAI tokens transferred to Compound
    function _mintCDai(uint256 _amount) 
        internal 
        returns (uint256) 
    {
        // identify the current balance of the saveDAI contract
        uint256 initialBalance = cDai.balanceOf(address(this));
        // mint cDai
        cDai.mint(_amount);
        // identify the updated balance of the saveDAI contract
        uint256 updatedBalance = cDai.balanceOf(address(this));
        // return number of cDAI tokens minted
        return updatedBalance.sub(initialBalance);
    }
}
