// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract IntensionHub {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    // view functions that should be satisfied at the end
    struct Intension {
        bytes32 location;
        uint256 target;
        // 0: eq
        // 1: gt
        // 2: lt
        uint8 operator;
    }

    /**
     * @notice anyone can submit calls to satisfy this goal, as long as all the intensions are satisfied at the end
     * @dev user should use permit instead of approve to maximize security + UX
     */
    function execute(Call[] calldata calls, Intension[] calldata intensions, bytes memory signatures) external {
        // todo: verify user signed intentions

        for (uint256 i = 0; i < calls.length;) {
            Call calldata call = calls[i];
            // call destination contract
            call.to.call{value: call.value}(call.data);

            unchecked {
                ++i;
            }
        }

        // verify end state, should reset all allowances!
        for (uint256 i = 0; i < intensions.length;) {
            bytes32 location = intensions[i].location;
            uint256 target = intensions[i].target;
            uint8 operator = intensions[i].operator;

            assembly {
                // load the storage slot
                let value := sload(location)
                switch operator
                case 0 {
                    // eq
                    if iszero(eq(value, target)) { revert(0, 0) }
                }
                case 1 {
                    // gt
                    if iszero(gt(value, target)) { revert(0, 0) }
                }
                case 2 {
                    // lt
                    if iszero(lt(value, target)) { revert(0, 0) }
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}
