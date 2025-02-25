// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {console} from "forge-std/console.sol";

contract InputOracle {
    bytes[] private inputs;
    uint private inputCounter;
    address private constant gwyneth = 0x9fCF7D13d10dEdF17d0f24C62f0cf4ED462f65b7;

    fallback() external payable {
        _handleInput();
    }

    receive() external payable {
        _handleInput();
    }

    function _handleInput() internal {
        if (msg.sender == gwyneth) {
            // When Gwyneth calls, return the recorded inputs
            bytes memory input = inputs[inputCounter++];
            assembly {
                return(add(input, 32), mload(input))
            }
        } else {
            // When others call, record their input
            inputs.push(msg.data);
            // Return dummy success value
            bytes32 success = bytes32(uint256(1));
            assembly {
                return(success, 32)
            }
        }
    }

    /// @notice Returns all recorded calls in the inbox
    /// @return An array of recorded input data
    function getCalls() public view returns (bytes[] memory) {
        return inputs;
    }
} 