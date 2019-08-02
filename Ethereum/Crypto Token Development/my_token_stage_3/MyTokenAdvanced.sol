pragma solidity ^0.5.10;

contract Administrable {
	address private _admin;

    event AdminshipTransferred(address indexed currentAdmin, address indexed newAdmin);

	constructor() internal {
		_admin = msg.sender;
        emit AdminshipTransferred(address(0), _admin);
	}

    function admin() public view returns (address) {
        return _admin;
    }

    function setAdmin(address initialAdmin) internal {
        _admin = initialAdmin;
    }

	modifier onlyAdmin() {
		require(msg.sender == _admin, "Only Admin can perform this action.");
		_;
	}

	function transferAdminship(address newAdmin) public onlyAdmin {
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
	}
}


contract MyToken {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) public {
        _balances[msg.sender] = initialSupply;
        _totalSupply = initialSupply;
        _decimals = decimalUnits;
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setTotalSupply(uint256 totalAmount) internal {
        _totalSupply = totalAmount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account, uint256 balance) internal {
        _balances[account] = balance;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAllowance(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }

    function transfer(address beneficiary, uint256 amount) public returns (bool) {
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_balances[msg.sender] >= amount, "Sender does not have enough balance.");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Addition overflow");

        _balances[msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(msg.sender, beneficiary, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        require(spender != address(0), "Spender address cannot be zero.");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address beneficiary, uint256 amount)  public returns (bool) {
        require(sender != address(0), "Sender address cannot be zero.");
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(amount <= _allowances[sender][msg.sender], "Allowance is not enough");
        require(_balances[sender] >= amount, "Sender does not have enough balance.");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Addition overflow");

        _balances[sender] -= amount;
        _allowances[sender][msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(sender, beneficiary, amount);
        return true;
    }
}


contract MyTokenAdvanced is MyToken, Administrable {
    mapping (address => bool) private _frozenAccounts;
    mapping (address => uint) private _pendingWithdrawals;

    uint256 private _sellPrice = 1; // ether per token
    uint256 private _buyPrice = 1;  // ether per token

    event FrozenFund(address indexed target, bool frozen);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits, address newAdmin) public
        MyToken(0, tokenName, tokenSymbol, decimalUnits) {
            if(newAdmin != address(0) && newAdmin != msg.sender)
                transferAdminship(newAdmin);

            setBalance(admin(), initialSupply);
            setTotalSupply(initialSupply);
    }

    function sellPrice() public view returns (uint256) {
        return _sellPrice;
    }

    function buyPrice() public view returns (uint256) {
        return _buyPrice;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyAdmin {
        require(newSellPrice > 0, "Sell price cannot be zero.");
        require(newBuyPrice > 0, "Buy price cannot be zero.");

        _sellPrice = newSellPrice;
        _buyPrice = newBuyPrice;
    }

    function mintToken(address target, uint256 mintedAmount) public onlyAdmin {
        require(balanceOf(target) + mintedAmount > balanceOf(target), "Addition overflow");
        require(totalSupply() + mintedAmount > totalSupply(), "Addition overflow");

        setBalance(target, balanceOf(target) + mintedAmount);
        setTotalSupply(totalSupply() + mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyAdmin {
        _frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze);
    }

    function transfer(address beneficiary, uint256 amount) public returns (bool) {
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(balanceOf(msg.sender) >= amount, "Sender does not have enough balance.");
        require(balanceOf(beneficiary) + amount > balanceOf(beneficiary), "Addition overflow");
        require(!_frozenAccounts[msg.sender], "Sender's account is frozen.");

        setBalance(msg.sender, balanceOf(msg.sender) - amount);
        setBalance(beneficiary, balanceOf(beneficiary) + amount);
        emit Transfer(msg.sender, beneficiary, amount);
        return true;
    }

    function transferFrom(address sender, address beneficiary, uint256 amount)  public returns (bool) {
        require(sender != address(0), "Sender address cannot be zero.");
        require(beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(amount <= allowance(sender, msg.sender), "Allowance is not enough");
        require(balanceOf(sender) >= amount, "Sender does not have enough balance.");
        require(balanceOf(beneficiary) + amount > balanceOf(beneficiary), "Addition overflow");
        require(!_frozenAccounts[sender], "Sender's account is frozen.");

        setBalance(sender, balanceOf(sender) - amount);
        setAllowance(sender, msg.sender, allowance(sender, msg.sender) - amount);
        setBalance(beneficiary, balanceOf(beneficiary) + amount);
        emit Transfer(sender, beneficiary, amount);
        return true;
    }

    function buy() public payable {
        uint256 amount = (msg.value/(1 ether)) / _buyPrice;
        address thisContractAddress = address(this);

        require(balanceOf(thisContractAddress) >= amount, "Contract does not have enough tokens.");
        require(balanceOf(msg.sender) + amount > balanceOf(msg.sender), "Addition overflow");

        setBalance(thisContractAddress, balanceOf(thisContractAddress) - amount);
        setBalance(msg.sender, balanceOf(msg.sender) + amount);
        emit Transfer(thisContractAddress, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        address thisContractAddress = address(this);

        require(balanceOf(msg.sender) >= amount, "Seller does not have enough tokens.");
        require(balanceOf(thisContractAddress) + amount > balanceOf(thisContractAddress), "Addition overflow");

        setBalance(msg.sender, balanceOf(msg.sender) - amount);
        setBalance(thisContractAddress, balanceOf(thisContractAddress) + amount);
        uint256 saleProceed = amount * _sellPrice * (1 ether);
        _pendingWithdrawals[msg.sender] += saleProceed;
        emit Transfer(msg.sender, thisContractAddress, amount);
    }

    function withdraw() public {
        uint amount = _pendingWithdrawals[msg.sender];
        _pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}
