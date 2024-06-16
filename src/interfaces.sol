// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRewardDistributor {
    function claim(address _account, uint256 _claimable, bytes32[] memory _proof) external;
}


interface IMetaMorpho {
    function asset() external returns (address asset);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}