    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.20;
    contract BABACOIN {
        string public name;
        string public symbol;
        uint8 public decimals = 18;
        uint public supply;
        address public owner;
        uint public rate = 1000;
        bool private locked;
        uint fee;
        uint buyFee = 5;
        uint sellFee = 7;
        bool private isPaused=false;
        mapping(address=>uint) private sellTime;
        mapping(address=>uint) private Balance;
        mapping(address=>uint[]) private depositHistory;
        mapping(address=>uint[]) private withdrawlHistory;
        mapping(address=>mapping(address=>uint)) public allowance;
        event Buy(address indexed from,uint amount);
        event Withdraw(address indexed from,uint amount);
        event Transfer(address indexed from,address indexed to,uint amount);
        event Approval(address indexed from,address indexed to,uint amount);
        constructor(string memory _name,string memory _symbol,uint _supply){
            name = _name;
            symbol = _symbol;
            supply = _supply*10**uint256(decimals);
            owner = msg.sender;
            Balance[owner] = supply;
        }
        modifier onlyOwner{
            require(msg.sender==owner,"Not Authorised");
            _;
        }
        modifier noReenterancy{
            require(!locked,"No Reenterancy");
            locked = true;
            _;
            locked = false;
        }
        modifier isPausedOrNot() {
            require(!isPaused,"Already Paused");
            _;
        }
        modifier notPaused() {
            require(isPaused,"Not Paused");
            _;
        }
        function buyCoin() public isPausedOrNot payable{
            require(msg.value!= 0,"Must Greater Than 0 ETHER");
            require(Balance[owner]>0,"No Tokens Left TO SELL");
            fee += msg.value*buyFee/100;
            uint tokens = msg.value - msg.value*buyFee/100;
            uint coinValue = tokens*rate;
            coinValue = coinValue*10**uint(decimals);
            Balance[owner] -= coinValue;
            Balance[msg.sender] += coinValue;
            depositHistory[msg.sender].push(msg.value);
            emit Buy(msg.sender, msg.value);
            sellTime[msg.sender] = block.timestamp + 2 hours;
        }
        function transfer(address to,uint amount) isPausedOrNot public returns(bool){
            require(Balance[msg.sender]>= amount,"Not Enough Balance");
            Balance[msg.sender] -= amount;
            Balance[to] += amount;
            emit Transfer(msg.sender, to,amount);
            return true;
        }
        function totalSupply() public view returns(uint){
            return supply;
        }
        function balanceOf(address _address) public view returns(uint){
            return Balance[_address];
        }
        function feeOwnerWithdraw() public onlyOwner {
            require(fee>0,"Not Collected");
            (bool success, ) = payable(msg.sender).call{value : fee}("");
            require(success,"Transaction Failed");
        }
        function withdraw(uint _amount) public noReenterancy isPausedOrNot{
            require(sellTime[msg.sender]<=block.timestamp,"Must Wait 2 Hours For Withdraw");
            require(Balance[msg.sender]>_amount,"Not Enough Balance");
            uint tokenamount = (_amount/(10**uint(decimals)))/rate;
            uint fees = ((_amount/(10**uint(decimals)))/rate)*sellFee/100;
            fee += fees;
            uint values = tokenamount - fees;
            require(address(this).balance>=values,"Not Enough Balance In The Pool");
            (bool success, ) = payable(msg.sender).call{value : values}("");
            require(success,"Transfer Failed");
            Balance[msg.sender] -= _amount;
            Balance[owner] += _amount;
            withdrawlHistory[msg.sender].push(_amount);
            emit Withdraw(msg.sender, _amount);
        }
        function emergencyPaused() public isPausedOrNot onlyOwner {
            isPaused = true;
        }
        function disableEmergencyPause() public notPaused onlyOwner{
            isPaused = false;
        }
        function approve(address to,uint amount) public returns(bool){
            allowance[msg.sender][to] = amount;
            emit Approval(msg.sender, to, amount);
            return true;
        }
        function transferFrom(address from,address to,uint256 amount) public returns(bool){
            require(Balance[from]>=amount,"Not Enough Balance In User Account");
            require(allowance[from][msg.sender]>=amount,"Allowance Exceeded");
            Balance[from] -= amount;
            Balance[to] += amount;
            allowance[from][msg.sender] -= amount;
            emit Transfer(from, to, amount);
            return true;
        }
    }
