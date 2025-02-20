// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <0.9.0;
// EVM library
library EVM {
    address constant xCallOptionsAddress = address(0x04D2);
    bytes4 constant xCallOptionsMagic = bytes4(keccak256("XCALLOPTIONS"));
    address payable constant extensionOracle = payable(0x1ADB9959EB142bE128E6dfEcc8D571f07cd66DeE);

    uint constant l1ChainId = 1;
    uint16 constant version = 1;

    // Mock (Cecilia)
    uint constant sandboxOffset = 66;

    function deriveAddress(uint chainId, address originalAddr) 
        internal 
        pure 
        returns (address) 
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(chainId, originalAddr)))));
    }

    function xCallOnL1()
        internal
        view
        returns (bool)
    {
        return xCallOptions(l1ChainId);
    }

    function xCallOnL1(bool sandbox)
        internal
        view
        returns (bool)
    {
        return xCallOptions(l1ChainId, sandbox);
    }

    function xCallOptions(uint chainID)
        internal
        view
        returns (bool)
    {
        return xCallOptions(chainID, false);
    }

    function xCallOptions(uint chainID, bool sandbox)
        internal
        view
        returns (bool)
    {
        return xCallOptions(chainID, sandbox, tx.origin, address(this));
    }

    function xCallOptions(uint chainID, bool sandbox, address txOrigin, address msgSender)
        internal
        view
        returns (bool)
    {
        return xCallOptions(chainID, sandbox, txOrigin, msgSender, 0x0, "");
    }

    function xCallOptions(uint chainID, bool sandbox, bytes32 blockHash, bytes memory proof)
        internal
        view
        returns (bool)
    {
        return xCallOptions(chainID, sandbox, address(0), address(0), blockHash, proof);
    }

    function xCallOptions(uint chainID, bool sandbox, address txOrigin, address msgSender, bytes32 blockHash, bytes memory proof)
        internal
        view
        returns (bool)
    {
        // Call the custom precompile
        bytes memory input = abi.encodePacked(version, uint64(chainID), sandbox, txOrigin, msgSender, blockHash, proof);
        (bool success, bytes memory result) = xCallOptionsAddress.staticcall(input);
        return success && bytes4(result) == xCallOptionsMagic;
        
        // Mock (Cecilia)
        // Return true if the input is non-empty
        // return input.length > 0;
    }

    function isSandboxed(bytes memory callData) internal pure returns (bool) {
        if (callData.length >= 11) { // version(1) + chainID(8) + sandbox(1)
            return callData[10] == 0x01; // Check sandbox boolean
        }
        return false;
    }


    function isOnL1() internal view returns (bool) {
        return chainId() == l1ChainId;
    }

    function chainId() internal view returns (uint256) {
        return block.chainid;
    }


    function onChain(address addr, uint chainID)
        internal
        view
        returns (address)
    {

        if (block.chainid == 1 && chainID == 2) {
            return extensionOracle;
        } else {
            return deriveAddress(chainID, addr);
        }

        // (bool success, bytes memory result) = address(0x09).staticcall{gas: 1000}(new bytes(0));
        // bool is_simulation = !success || result.length > 1;

        // bool xCallOptionsAvailable = xCallOptions(chainID, false /* sandbox */);

        // if (xCallOptionsAvailable || is_simulation) {
        //     // return addr; 
        //     // Mock (Cecilia)
        //     if (chainID == chainId()) {
        //         return addr; // Same chain, return original address
        //     }
        //     return deriveAddress(chainID, addr); // Different chain, return derived address
        // } else {
        //     return extensionOracle; // 0x1ADB9959EB142bE128E6dfEcc8D571f07cd66DeE
        // }
    }

    

    function onChainSandboxed(address addr, uint chainID)
        internal
        view
        returns (address)
    {
        // Mock (Cecilia): derive a different address to bypass derived contract
        return deriveAddress(chainID + sandboxOffset, addr);
    }
}