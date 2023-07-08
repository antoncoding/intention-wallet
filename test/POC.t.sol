// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {IntensionHub} from "../src/IntensionHub.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract POCTests is Test {
    IntensionHub public hub;

    uint256 private _alicePk = uint256(0xaaaa);
    uint256 private _bobPk = uint256(0xbbbb);

    address public alice = vm.addr(_alicePk);
    address public bob = vm.addr(_bobPk);

    MockERC20 public usdc;
    MockERC20 public wbtc;

    function setUp() public {
        hub = new IntensionHub();

        usdc = new MockERC20("USDC", "USDC");
        wbtc = new MockERC20("WBTC", "WBTC");

        usdc.mint(alice, 10000e18);
        wbtc.mint(bob, 100e18);
    }

    function testTradeTokenDirectlyFromBob() public {
        // sign intensions
        IntensionHub.Intension[] memory intensions = new IntensionHub.Intension[](2);
        // USDC > 9000
        intensions[0] = IntensionHub.Intension({
            token: address(usdc),
            owner: alice,
            target: 9000e18,
            operator: 3 // gte
        });
        // WBTC > 1
        intensions[1] = IntensionHub.Intension({
            token: address(wbtc),
            owner: alice,
            target: 1e18,
            operator: 3 // gte
        });

        // all calls: bob transfer alice 1 btc, get 1000 USDC
        IntensionHub.Call[] memory calls = new IntensionHub.Call[](4);

        // calls[0]: permit: hub can transfer USDC from alice
        calls[0] = IntensionHub.Call({
            to: address(usdc),
            value: 0,
            data: _getPermitData(usdc, alice, address(hub), 1000e18, 0, block.timestamp, _alicePk)
        });
        // calls[1]: permit: hub can transfer WBTC from bob
        calls[1] = IntensionHub.Call({
            to: address(wbtc),
            value: 0,
            data: _getPermitData(wbtc, bob, address(hub), 1e18, 0, block.timestamp, _bobPk)
        });

        // calls[1]: transfer 1000 USDC from alice to bob
        calls[2] = IntensionHub.Call({
            to: address(usdc),
            value: 0,
            data: abi.encodeWithSelector(ERC20.transferFrom.selector, alice, bob, 1000e18)
        });
        // calls[3]: transfer 1 BTC to alice
        calls[3] = IntensionHub.Call({
            to: address(wbtc),
            value: 0,
            data: abi.encodeWithSelector(ERC20.transferFrom.selector, bob, alice, 1e18)
        });

        hub.execute(calls, intensions, "");
    }

    function _getPermitData(
        MockERC20 token,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        uint256 pk
    ) internal view returns (bytes memory) {
        bytes32 structHash = token.getPermitTypeHash(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, structHash);

        bytes memory data =
            abi.encodeWithSelector(ERC20Permit.permit.selector, owner, spender, value, deadline, v, r, s);
        return data;
    }
}
