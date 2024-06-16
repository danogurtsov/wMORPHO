// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626,SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {WMORPHO} from "../src/WMORPHO.sol";
import {Omnipool} from "../src/Omnipool.sol";

import {IRewardDistributor, IMetaMorpho} from "../src/interfaces.sol";

contract OmnipoolTest is Test {

    using SafeERC20 for IERC20;

    struct VaultWeight {
        address vaultAddress;
        uint256 weight;
    }

    address underlying = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
    uint256 decimals;

    address vault1 = 0xbEef047a543E45807105E51A8BBEFCc5950fcfBa; // Steakhouse USDT
    address vault2 = 0x2C25f6C25770fFEC5959D34B94Bf898865e5D6b1; // Flagship USDT
    address vault3 = 0x95EeF579155cd2C5510F312c8fA39208c3Be01a8; // Re7 USDT
    address vault4 = 0x8CB3649114051cA5119141a34C200D65dc0Faa73; // Gauntlet USDT

    address user1 = address(101);
    address user2 = address(102);

    Omnipool omnipool;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
        omnipool = new Omnipool(underlying, "tokenPool", "tokenPool");
        decimals = 10 ** ERC20(underlying).decimals();
    }

    function testDeploy() public {
        assertEq(omnipool.underlying(), underlying);
    }

    function _setUpWeights() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        omnipool.addVault(vault4);
        Omnipool.VaultWeight[] memory newWeights = new Omnipool.VaultWeight[](4);
        newWeights[0] = Omnipool.VaultWeight(vault1, 10_000);
        newWeights[1] = Omnipool.VaultWeight(vault2, 20_000);
        newWeights[2] = Omnipool.VaultWeight(vault3, 30_000);
        newWeights[3] = Omnipool.VaultWeight(vault4, 40_000);
        omnipool.setNewWeights(newWeights);
        uint256 initialAmount = 1_000_000 * decimals;
        deal(underlying, user1, initialAmount);
        deal(underlying, user2, initialAmount);
        vm.prank(user1);
        IERC20(underlying).forceApprove(address(omnipool), initialAmount);
        vm.prank(user2);
        IERC20(underlying).forceApprove(address(omnipool), initialAmount);
    }
    
    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    function testDeposit() public {
        _setUpWeights();
        vm.prank(user1);
        uint256 amount = 10_000 * decimals;
        omnipool.deposit(amount);
        assertApproxEqAbs(omnipool.balance(), amount, 10);
    }

    /*//////////////////////////////////////////////////////////////
                            VAULTS SETTERS
    //////////////////////////////////////////////////////////////*/

    function testAddAllVaults() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        omnipool.addVault(vault4);
    }

    function testVaultsAddSameTwice() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        vm.expectRevert();
        omnipool.addVault(vault2);
    }

    function testVaultsRemoveSameTwice() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        omnipool.addVault(vault4);
        omnipool.removePool(vault3);
        vm.expectRevert();
        omnipool.removePool(vault3);
    }

    function testGetVaultAtIndex() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        assertEq(omnipool.isRegisteredPool(vault4), false);
        omnipool.addVault(vault4);
        assertEq(omnipool.isRegisteredPool(vault3), true);
        omnipool.removePool(vault3);
        assertEq(omnipool.getVaultAtIndex(0), vault1);
        assertEq(omnipool.getVaultAtIndex(1), vault2);
        assertEq(omnipool.getVaultAtIndex(2), vault4);
    }

    /*//////////////////////////////////////////////////////////////
                                WEIGHTS
    //////////////////////////////////////////////////////////////*/

    function testCorrectWeights() public {
        // should not revert
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        Omnipool.VaultWeight[] memory newWeights = new Omnipool.VaultWeight[](3);
        newWeights[0] = Omnipool.VaultWeight(vault2, 25_000);
        newWeights[1] = Omnipool.VaultWeight(vault3, 35_000);
        newWeights[2] = Omnipool.VaultWeight(vault1, 40_000);
        omnipool.setNewWeights(newWeights);
        assertEq(omnipool.getWeight(vault2), 25_000);
        assertEq(omnipool.getWeight(vault3), 35_000);
        assertEq(omnipool.getWeight(vault1), 40_000);
    }

    function testWeightInputs() public {
        omnipool.addVault(vault1);
        omnipool.addVault(vault2);
        omnipool.addVault(vault3);
        // wrong sum
        Omnipool.VaultWeight[] memory newWeights = new Omnipool.VaultWeight[](3);
        newWeights[0] = Omnipool.VaultWeight(vault2, 25_000);
        newWeights[1] = Omnipool.VaultWeight(vault3, 35_000);
        newWeights[2] = Omnipool.VaultWeight(vault1, 0);
        vm.expectRevert();
        omnipool.setNewWeights(newWeights);
        // correact sum
        newWeights[2] = Omnipool.VaultWeight(vault1, 40_000);
        omnipool.setNewWeights(newWeights);
        // wrong length
        Omnipool.VaultWeight[] memory newWeights2 = new Omnipool.VaultWeight[](2);
        newWeights2[0] = Omnipool.VaultWeight(vault2, 50_000);
        newWeights2[1] = Omnipool.VaultWeight(vault3, 50_000);
        vm.expectRevert();
        omnipool.setNewWeights(newWeights2);
        // removal: revert if weight set
        vm.expectRevert();
        omnipool.removePool(vault2);
        // removal: success for zero weight vault
        Omnipool.VaultWeight[] memory newWeights3 = new Omnipool.VaultWeight[](3);
        newWeights3[0] = Omnipool.VaultWeight(vault2, 0);
        newWeights3[1] = Omnipool.VaultWeight(vault3, 50_000);
        newWeights3[2] = Omnipool.VaultWeight(vault1, 50_000);
        omnipool.setNewWeights(newWeights3);
        omnipool.removePool(vault2);
        assertEq(omnipool.getVaultAtIndex(0), vault1);
        assertEq(omnipool.getVaultAtIndex(1), vault3);
        assertEq(omnipool.vaultsCount(), 2);
        vm.expectRevert();
        omnipool.getVaultAtIndex(2);

    }

}
