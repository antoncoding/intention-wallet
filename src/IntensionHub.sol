// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract IntensionHub is Ownable {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    // view functions that should be satisfied at the end
    struct Intension {
        address token;
        address owner;
        uint256 target;
        // 0: eq
        // 1: gt
        // 2: lt
        // 3: gte
        // 4: lte
        uint8 operator;
    }

    /**
     * @notice anyone can submit calls to satisfy this goal, as long as all the intensions are satisfied at the end
     * @dev user should use permit instead of approve to maximize security + UX
     */
    function execute(Call[] calldata calls, Intension[] calldata intensions, bytes memory signature) external {
        _verifySignatures(intensions, signature);

        // do arbitrary calls found by the searcher
        _executeCalls(calls);

        // verify end state, make sure funds are transferred, all requirements are met!
        _assertIntensions(intensions);
    }

    function _verifySignatures(Intension[] calldata, /*intensions*/ bytes memory /*signature*/ ) internal view {
        // todo: verify user signed intentions
    }

    function _executeCalls(Call[] calldata calls) internal {
        for (uint256 i = 0; i < calls.length;) {
            Call calldata call = calls[i];
            // call destination contract
            call.to.call{value: call.value}(call.data);

            unchecked {
                ++i;
            }
        }
    }

    function _assertIntensions(Intension[] calldata intensions) internal view {
        for (uint256 i = 0; i < intensions.length;) {
            uint256 target = intensions[i].target;
            uint8 operator = intensions[i].operator;

            // todo: generalized to any view functions
            uint256 newBalance = IERC20(intensions[i].token).balanceOf(intensions[i].owner);

            assembly {
                // load the storage slot
                switch operator
                case 0 {
                    // eq
                    if iszero(eq(newBalance, target)) { revert(0, 0) }
                }
                case 1 {
                    // gt
                    if iszero(gt(newBalance, target)) { revert(0, 0) }
                }
                case 2 {
                    // lt
                    if iszero(lt(newBalance, target)) { revert(0, 0) }
                }
                case 3 {
                    // gte
                    if lt(newBalance, target) { revert(0, 0) }
                }
                case 4 {
                    // lte
                    if gt(newBalance, target) { revert(0, 0) }
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}
