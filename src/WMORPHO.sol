// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {
    IERC20,
    IERC4626,
    ERC20,
    ERC4626,
    Math,
    SafeERC20
} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract WMORPHO is ERC4626{

    IERC20 public MORPHO;

    constructor(
        address _morphoToken,
        string memory _name,
        string memory _symbol
        ) ERC4626(IERC20(_morphoToken)) ERC20(_name, _symbol) {
        MORPHO = IERC20(_morphoToken);
    }

}
