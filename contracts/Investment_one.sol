// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Investment1 {
    uint public goal;
    address public admin;
    uint public countOfContributors;
    uint public minContribution;
    uint public raisedAmount;
    mapping(address => uint) public contributors;
    
    enum Status{Open, Closed}
    Status status;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint countOfVoters;
        mapping(address => bool) votes;
    }
    mapping(uint => Request) public requests;
    uint public countRequests;
    
    event contributionSuccessfull (address _contributor, uint _value);
    event refundingComplete (address _recipient);
    event spendRequestExisted(string _description, address _recipient, uint _value);
    event paymentSuccessfull(uint _numberOfRequest, address _recipient, uint _value);
    
    constructor(){
        status = Status.Open;
        //goal = _goal;
        //minContribution = _mincontrib;
        goal = 200 ether;
        minContribution = 0.1 ether;
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can do this");
        _;
    }
    
    modifier ifOpen() {
        require(status == Status.Open, "Unfortunately, the crowdfunding was stopped or paused");
        _;
    }
    
    modifier onlyInvestor(){
        require(contributors[msg.sender] > 0, "Only investors can do this");
        _;
    }
    
    //ПРИСОЕДИНЕНИЕ К КАМПАНИИ
    function contribute() public payable ifOpen {
        require(msg.value >= minContribution, "Your value is less then minimum contribution");
        
        if(contributors[msg.sender] == 0) countOfContributors++;
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        if(raisedAmount >= goal) status = Status.Closed;
        
        emit contributionSuccessfull(msg.sender, msg.value);
    }
    
    receive() payable external{
        contribute();
    }
    
    //ЗАПРОС БАЛАНСА КОНТРАКТА
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    //ЗАПРОС НА ВОЗВРАТ СРЕДСТВ
    function refund() public onlyInvestor {
        
        payable(msg.sender).transfer(contributors[msg.sender]); //payment
        
        countOfContributors --;
        raisedAmount -= contributors[msg.sender];
        contributors[msg.sender] = 0;
        
        status = raisedAmount >= goal? Status.Closed: Status.Open;
        
        emit refundingComplete(msg.sender);
    }
    
    //ЗАПРОС НА РАСХОДОВАНИЕ СРЕДСТВ 
    function spendRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[countRequests];
        countRequests++;
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.countOfVoters = 0;
        
        emit spendRequestExisted(_description, _recipient, _value);
    }
    
    //ГОЛОСОВАНИЕ ПО ЗАПРОСАМ
    function voting(uint _numberOfRequest) public onlyInvestor{
        Request storage thisRequest = requests[_numberOfRequest];
        require(thisRequest.votes[msg.sender] = false, "You have already voted!");
        thisRequest.countOfVoters++;
        thisRequest.votes[msg.sender] = true;
    }
    
    //ПРОВЕДЕНИЕ ПЛАТЕЖА ПО ЗАПРОСУ
    function makePayment(uint _numberOfRequest) public onlyAdmin{
        Request storage thisRequest = requests[_numberOfRequest];
        require(thisRequest.completed == false, "This request has been completed");
        require(thisRequest.countOfVoters >= ((countOfContributors/100)*51), "This request got less then 51% votes");
        thisRequest.recipient.transfer(thisRequest.value);
        
        emit paymentSuccessfull(_numberOfRequest, thisRequest.recipient, thisRequest.value);
    }
    
    function getStatus() public view returns(string memory _status){
        return status == Status.Open? "Open" : "Closed";
    }
}