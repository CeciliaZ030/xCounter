// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {xERC20} from "../src/xERC20.sol";
import {CrossChainUtils} from "./utils.sol";
import {GwynethData} from "../src/protocol/GwynethData.sol";
import {EVM} from "../src/common/MockEVM.sol";

contract xERC20Test is Test {
    xERC20 public token;
    xERC20 public l2_token;
    address public owner;
    address public user1;
    address public user2;
    uint256 constant INITIAL_SUPPLY = 1000000;
    uint256 constant L1 = 31337;
    uint256 constant L2 = 42161;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        token = new xERC20(INITIAL_SUPPLY);
        
        address derivedAddr = EVM.mirrorAddress(L2, address(token));
        vm.etch(derivedAddr, address(token).code);
        l2_token = xERC20(payable(derivedAddr));
    }

    // Basic ERC20 functionality tests
    function test_InitialSupply() public {
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_Transfer() public {
        uint256 amount = 100;
        token.transfer(user1, amount);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        vm.expectRevert("Insufficient balance");
        token.transfer(user1, INITIAL_SUPPLY + 1);
    }

    function test_Approve() public {
        uint256 amount = 100;
        token.approve(user1, amount);
        assertEq(token.allowance(owner, user1), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 100;
        token.approve(user1, amount);
        
        vm.prank(user1);
        token.transferFrom(owner, user2, amount);
        
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(owner, user1), 0);
    }

    // Cross-chain functionality tests
    function test_xTransfer() public {
        uint256 amount = 100;

        // Set up input oracel for L2 on L1
        CrossChainUtils.switch_and_simulate(L2, address(token), true);

        token.xTransfer(L2, user1, amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY- amount);

        // Relay the calls to L2
        CrossChainUtils.relay_xCalls(address(token), L2, address(l2_token));
        assertEq(l2_token.balanceOf(user1), amount);

    }

    function test_xApprove() public {
        uint256 amount = 100;

        // Set up input oracel for L2 on L1
        CrossChainUtils.switch_and_simulate(L2, address(token), true);

        token.xApprove(L2, user1, amount);

        // Relay the calls to L2
        CrossChainUtils.relay_xCalls(address(token), L2, address(l2_token));

        assertEq(l2_token.allowance(owner, user1), amount);
    }
}
