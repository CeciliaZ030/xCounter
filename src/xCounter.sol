// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GwynethContract} from "./common/GwynethContract.sol";
import {DelegateContract} from "./common/DelegateContract.sol";
import {EVM} from "./common/MockEVM.sol";

contract Counter is GwynethContract, DelegateContract {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function incrementBy(uint256 amount) public returns (uint256) {
        number += amount;
        return number;
    }

    function incrementOn(uint chainId) public {
        Counter counter = Counter(payable(EVM.onChain(address(this), chainId)));
        counter.increment();
    }

    function incrementByOn(uint256 chainId, uint256 amount) public returns (uint256) {
        address target = EVM.onChain_(address(this), chainId);
        // Explicitly construct the incrementBy call
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSignature("incrementBy(uint256)", amount)
        );
        require(success, string(abi.encodePacked("Call failed: ", data)));
        return abi.decode(data, (uint256));
    }

}
