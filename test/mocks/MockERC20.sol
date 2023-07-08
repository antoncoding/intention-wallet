// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20, ERC20Permit {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(string memory _name, string memory _symbol) ERC20Permit(_name) ERC20(_name, _symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function getPermitTypeHash(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)
        external
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        return _hashTypedDataV4(structHash);
    }
}
