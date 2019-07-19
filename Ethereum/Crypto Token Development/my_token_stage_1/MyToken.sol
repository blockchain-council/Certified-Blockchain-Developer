pragma solidity ^0.5.10;

contract MyToken {
    mapping (address => uint256) private _balances;

    constructor(uint256 initialSupply) public {
        _balances[msg.sender] = initialSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account, uint256 balance) internal {
        _balances[account] = balance;
    }

    function transfer(address beneficiary, uint256 amount) public returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[beneficiary] += amount;
        return true;
    }
}