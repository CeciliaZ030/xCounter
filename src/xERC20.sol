// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./common/MockEVM.sol";
import "./common/GwynethContract.sol";

contract xERC20 is GwynethContract {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    using EVM for address;

    function ChainAddress(uint256 chainId, xERC20 contractAddr) internal view returns (xERC20) {
        // return xERC20(address(contractAddr).onChain(chainId));
        return xERC20(address(contractAddr).onChain_(chainId));
    }

    function on(uint256 chainId) internal view returns (xERC20) {
        return ChainAddress(chainId, this);
    }

    constructor(uint256 totalSupply) {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (uint256) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return value;
    }

    function xTransfer(uint256 fromChain, uint256 toChain, address to, uint256 value) public returns (uint256) {
        return on(fromChain)._xTransfer(msg.sender, toChain, to, value);
    }

    function _transfer(address from, address to, uint256 value) public returns (uint256) {
        //require(msg.sender == address(this), "Only this contract can mint");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return value;
    }

    function _mint(address to, uint256 value) public returns (uint256) {
        //require(msg.sender == address(this), "Only this contract can mint");
        balanceOf[to] += value;
        return value;
    }

    function _xTransfer(address from, uint256 chain, address to, uint256 value) external returns (uint256) {
        //require(msg.sender == address(this), "Only contract itself can call this function");
        balanceOf[from] -= value;
        return on(chain)._mint(to, value);
    }

    function xTransfer(uint256 chain, address to, uint256 value) public returns (uint256) {
        balanceOf[msg.sender] -= value;
        return on(chain)._mint(to, value);
    }

    function sandboxedTransfer(uint256 chain, address to, uint256 value) public returns (uint256) {
        EVM.xCallOptions(chain, true);
        return this._transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (uint256) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return value;
    }

    function _approve(address owner, address spender, uint256 value) public returns (uint256) {
        require(msg.sender == address(this), "Only contract itself can call this function");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
        return value;
    }

    function xApprove(uint256 chain, address spender, uint256 value) public returns (uint256) {
        return on(chain)._approve(msg.sender, spender, value);
        address mirror = EVM.onChain_(address(this), chain);
    }

    function transferFrom(address from, address to, uint256 value) public returns (uint256) {
        require(balanceOf[from] >= value, "Insufficient balance");
        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        }
        balanceOf[from] -= value;
        balanceOf[to] += value;
        if (from != msg.sender) {
            allowance[from][msg.sender] -= value;
        }
        emit Transfer(from, to, value);
        return value;
    }
}
