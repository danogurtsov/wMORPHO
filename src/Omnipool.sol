// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20, ERC4626,SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardDistributor, IMetaMorpho} from "./interfaces.sol";

import {Test, console} from "forge-std/Test.sol";

/**
    @title Omnipool
    @author TODO, inspired by Conic Finance and Curve Finance
    @notice TODO
 */
contract Omnipool is Ownable, ERC4626 {

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // WEIGHTS

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap internal weights;
    uint256 totalWeight = 100_000;

    struct VaultWeight {
        address vaultAddress;
        uint256 weight;
    }

    // VAULTS

    EnumerableSet.AddressSet vaults;
    uint256 maxVaults = 15;

    address public underlying;

    // REWARDS

    mapping (address user => uint256 integral) public userIntegral;
    uint256 public totalIntegral;

    /*//////////////////////////////////////////////////////////////
                            EVENTS & ERRORS
    //////////////////////////////////////////////////////////////*/

    event VaultAdded(address vault);
    event VaultRemoved(address vault);
    event NewWeight(address vault, uint256 weight);




    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor (
        address _underlying,
        string memory _name,
        string memory _symbol
        ) Ownable(msg.sender) ERC4626(IERC20(_underlying)) ERC20(_name, _symbol) {
        underlying = _underlying;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function rebalance() public {
    }

    function balance() public returns(uint256) {
        uint256 total;
        for (uint256 i; i < weights.length(); i++) {
            (address vault, ) = weights.at(i);
            uint256 shares = IERC20(vault).balanceOf(address(this));
            uint256 assets =  IERC4626(vault).convertToAssets(shares);
            total += assets;
        }
        return total;
    }

    function deposit(uint256 _amountUnderlying) public {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this),_amountUnderlying);
        for (uint256 i; i < weights.length(); i++) {
            (address vault, uint256 weight) = weights.at(i);
            _deposit(vault, _amountUnderlying * weight / totalWeight);
        }
    }

    function _deposit(address _vault, uint256 _amountUnderlying) internal {
        IMetaMorpho(_vault).deposit(_amountUnderlying, address(this));
    }

    function _withdraw(address _vault, uint256 _amountUnderlying) internal {
        IMetaMorpho(_vault).withdraw(_amountUnderlying, address(this), address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            WEIGHT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setNewWeights(VaultWeight[] memory newWeights) public onlyOwner {
        require(newWeights.length == vaults.length(), "invalid pool weights");
        uint256 total;
        address previousPool;
        for (uint256 i; i < newWeights.length; i++) {
            address vault = newWeights[i].vaultAddress;
            require(weights.contains(vault));
            uint256 newWeight = newWeights[i].weight;
            weights.set(vault, newWeight);
            total += newWeight;
            previousPool = vault;
            emit NewWeight(vault, newWeight);
        }

        require(total == totalWeight, "weights do not sum to 1");
    }

    function addVault(address _vault) public onlyOwner {
        require(IMetaMorpho(_vault).asset() == underlying);
        require(vaults.length() < maxVaults, "Max vaults reached");
        require(!vaults.contains(_vault), "Vault already added");
        if (!weights.contains(_vault)) weights.set(_vault, 0);
        require(vaults.add(_vault), "failed to add pool");
        IERC20(underlying).forceApprove(_vault, type(uint256).max);
        emit VaultAdded(_vault);
    }

    function removePool(address _vault) external onlyOwner {
        require(vaults.contains(_vault), "Vault not added");
        require(vaults.length() > 1, "Cannot remove the last vault");
        uint256 weight = weights.get(_vault);
        require(weight == 0, "Vault has weight set, should be removed first");
        require(vaults.remove(_vault), "Vault not removed");
        require(weights.remove(_vault), "weight not removed");
        IERC20(underlying).forceApprove(_vault, 0);
        emit VaultRemoved(_vault);
    }



    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/

    function allVaults() external view returns (address[] memory) {
        return vaults.values();
    }

    function vaultsCount() external view returns (uint256) {
        return vaults.length();
    }

    function getVaultAtIndex(uint256 _index) external view returns (address) {
        return vaults.at(_index);
    }

    function isRegisteredPool(address _vault) public view returns (bool) {
        return vaults.contains(_vault);
    }

    function getWeight(address _vault) external view returns (uint256) {
        return weights.get(_vault);
    }

    function getWeights() external view returns (VaultWeight[] memory) {
        uint256 length_ = vaults.length();
        VaultWeight[] memory weights_ = new VaultWeight[](length_);
        for (uint256 i; i < length_; i++) {
            (address vault, uint256 weight) = weights.at(i);
            weights_[i] = VaultWeight(vault, weight);
        }
        return weights_;
    }

}