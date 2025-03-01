// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {EVM} from "../src/common/MockEVM.sol";
import {GwynethData} from "../src/protocol/GwynethData.sol";
import {InputOracle} from "../src/protocol/InputOracle.sol";
import {ExtensionOracle} from "../src/protocol/ExtensionOracle.sol";

library CrossChainUtils {
    function switch_and_simulate(uint256 chain_id, address target, bool is_simulation) internal {
        Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
        vm.chainId(chain_id);
        // Set mock call data based on is_simulation flag
        bytes memory flag = is_simulation ? bytes(hex"0000") : bytes(hex"00");

        // If simulation, set up input oracle
        if (is_simulation) {
            InputOracle inputOracle = new InputOracle();
            address inbox = EVM.inboxAddress(chain_id, target);
            vm.etch(inbox, address(inputOracle).code);
            console.logAddress(inbox);
        }

        vm.mockCall(
            address(0x09),
            abi.encode(),
            flag  // Two bytes for simulation, one byte otherwise
        );
    }

    function relay_xCalls(
        address mirror, 
        uint toChain, 
        address target
    ) internal {
        Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
        // Get the inbox address and retrieve recorded calls
        address inbox = EVM.inboxAddress(toChain, mirror);
        InputOracle inboxOracle = InputOracle(payable(inbox));
        bytes[] memory calls = inboxOracle.getCalls();
        
        // Switch to toChain and execute calls directly on the counter
        vm.chainId(toChain);
        for (uint256 i = 0; i < calls.length; i++) {
            // Cross-chain Apps has the same address on all chains
            vm.prank(target);
            (bool success,) = target.call(calls[i]);
            require(success, "Call failed");
        }
    }

    function build_xCalls(
        uint256 chain_id,
        address target,
        uint256 numCalls
    ) internal returns (GwynethData.ReturnData[] memory) {
        Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
        vm.chainId(chain_id);
        GwynethData.ReturnData[] memory returnDataArray = new GwynethData.ReturnData[](numCalls);
        
        // Get the inbox address and cast it to InputOracle
        address inbox = EVM.inboxAddress(chain_id, target);
        InputOracle inboxOracle = InputOracle(payable(inbox));
        
        // Get the recorded calls from the inbox and execute them
        address mirror = EVM.mirrorAddress(chain_id, target);
        bytes[] memory calls = inboxOracle.getCalls();

        console.log("building xCalls:", calls.length);
        for (uint256 i = 0; i < numCalls; i++) {
            (bool success, bytes memory result) = mirror.call(calls[i]);
            console.logBytes(result);
            returnDataArray[i] = GwynethData.ReturnData({
                isRevert: !success,
                data: result
            });
        }
        
        return returnDataArray;
    }

    function build_oracle(GwynethData.ReturnData[] memory returnDataArray) internal {
        Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
        ExtensionOracle oracle = new ExtensionOracle();
        vm.etch(EVM.extensionOracle, address(oracle).code);
        
        vm.prank(0x9fCF7D13d10dEdF17d0f24C62f0cf4ED462f65b7);
        (bool ok,) = EVM.extensionOracle.call(abi.encode(returnDataArray));
        require(ok, "Failed to set return data");

        vm.mockCall(
            address(0x09),
            abi.encode(),
            hex"00"  // Single byte makes is_simulation false
        );
    }
}