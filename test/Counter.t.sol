// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/xCounter.sol";
import {DelegateContract} from "../src/common/DelegateContract.sol";
import {EVM} from "../src/common/MockEVM.sol";
import {ExtensionOracle} from "../src/protocol/ExtensionOracle.sol";
import {GwynethData} from "../src/protocol/GwynethData.sol";
import {InputOracle} from "../src/protocol/InputOracle.sol";
import {CrossChainUtils} from "./utils.sol";

contract CounterTest is Test {
    Counter public counter;
    Counter public mirrorCounter;
    
    uint256 constant L1 = 31337; // Default forge chainId
    uint256 constant CHAIN_1 = 1;
    uint256 constant CHAIN_2 = 2;

    address derivedAddr;

    function setUp() public {
        // Deploy source chain counter
        counter = new Counter();
        counter.setNumber(0);
        
        // Deploy derived counter at the calculated address
        derivedAddr = EVM.mirrorAddress(CHAIN_2, address(counter));
        vm.etch(derivedAddr, address(counter).code);
        mirrorCounter = Counter(payable(derivedAddr));
        mirrorCounter.setNumber(0);

        // Deploy input oracle at the inbox address
        InputOracle inputOracle = new InputOracle();
        address inbox = EVM.inboxAddress(CHAIN_2, address(counter));
        vm.etch(inbox, address(inputOracle).code);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function test_L2ToL1withSubCall() public {
        CrossChainUtils.switch_and_simulate(L1, address(mirrorCounter), true);

        // Record first call (goes to inbox)
        mirrorCounter.incrementByOn(L1, 1);
        mirrorCounter.incrementByOn(L1, 2);
        mirrorCounter.incrementByOn(L1, 3);

        // Execute the recorded calls
        CrossChainUtils.relay_xCalls(address(mirrorCounter),L1, address(counter));
        
        // Verify the changes
        assertEq(counter.number(), 6, "L1 counter should have accumulated changes");
        assertEq(mirrorCounter.number(), 0, "L2 counter should not change");
    }

    function test_L1ToL2withOracle() public {
        CrossChainUtils.switch_and_simulate(CHAIN_1, address(counter), true);
        
        // Record first call (goes to inbox)
        counter.incrementByOn(CHAIN_2, 6);
        counter.incrementByOn(CHAIN_2, 7);
        counter.incrementByOn(CHAIN_2, 8);
        counter.incrementByOn(CHAIN_2, 9);

        // 2. Replay on L2 and collect output
        GwynethData.ReturnData[] memory output = CrossChainUtils.build_xCalls(CHAIN_2, address(counter), 4);

        // 3. Set up oracle and prepare for second call
        vm.chainId(L1);
        CrossChainUtils.build_oracle(output);
        
        // Store initial L1 counter value
        uint256 initialL1Value = counter.number();
        
        counter.incrementByOn(CHAIN_2, 6);
        counter.incrementByOn(CHAIN_2, 7);
        counter.incrementByOn(CHAIN_2, 8);
        counter.incrementByOn(CHAIN_2, 9);

        // Verify L1 counter hasn't changed
        assertEq(counter.number(), initialL1Value, "L1 counter should not change");
        
        // Switch to L2 and verify the changes happened there
        vm.chainId(CHAIN_2);
        assertEq(mirrorCounter.number(), 30, "L2 counter should have accumulated changes");
    }
}

