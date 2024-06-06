// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {
    IERC20,
    IERC4626,
    ERC20,
    ERC4626,
    Math,
    SafeERC20
} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import {Ownable} from "openzeppelin/access/Ownable.sol";


import {IRewardDistributor} from "./interfaces.sol";

contract Omnipool is Ownable, ERC4626 {

    address token;

    address[] vaults;
    uint256[] weights;

    uint256 totalWeight = 100_000;
    uint256 maxVaults = 15;

    constructor (
        address _token,
        string memory _name,
        string memory _symbol
        ) Ownable(msg.sender) ERC4626(IERC20(_token)) ERC20(_name, _symbol) {
        token = _token;
    }

    /*//////////////////////////////////////////////////////////////
                            WEIGHT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setTargetPercentages(uint256[] memory newTargetWeights) public onlyOwner {
        require(newTargetWeights.length == targetVaults.length, "Wrong length");
        uint256 sum;
        for (uint256 i = 0; i < newTargetWeights.length; i++) {
            sum += newTargetWeights[i];
        }
        require(sum == totalWeight, "Target Percentage is not 100 000");
        targetWeights = newTargetWeights;
    }

    function addVault() public onlyOwner {
        require(vaults.length() < maxVaults, "Max vaults reached");
    }

    function removeVault() public onlyOwner {

    }

    function setTargetVaults(address[] memory newTargetVaults) public onlyOwner {
        targetVaults = newTargetVaults;
    }

    function rebalance() public {

    }

}