// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRewardDistributor {
    function claim(address _account, uint256 _claimable, bytes32[] memory _proof) external;
}