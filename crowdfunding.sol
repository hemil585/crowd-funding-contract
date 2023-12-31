// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public manager;
    uint256 public raisedAmount;
    uint256 public minimumContribution;
    uint256 public noOfContributors;
    uint256 public deadline;
    uint256 public target;

    struct Request {
        /* Requesting for crowd funding */
        string description;
        address payable recipient;
        uint256 requiredFund;
        uint256 noOfVoters;
        bool completed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;
    uint256 public noOfRequests;

    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can access!");
        _;
    }

    modifier onlyContrubutor() {
        require(contributors[msg.sender] > 0, "You must be a contributor");
        _;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Time has over for this funding");
        require(msg.value >= minimumContribution, "Contribute atleast 100 wei");

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public onlyContrubutor {
        require(
            block.timestamp > deadline && raisedAmount < target,
            "Refund failed!"
        );
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    function createRequest(
        string memory _desc,
        uint256 _requiredFund,
        address payable _recipient
    ) public onlyManager {
        Request storage newReq = requests[noOfRequests];
        noOfRequests++;
        newReq.description = _desc;
        newReq.recipient = _recipient;
        newReq.requiredFund = _requiredFund;
        newReq.completed = false;
        newReq.noOfVoters = 0;
    }

    function voteRequest(uint256 _req) public onlyContrubutor {
        Request storage thisReq = requests[_req];
        require(
            thisReq.voters[msg.sender] == false,
            "You can't vote multiple times"
        );
        thisReq.voters[msg.sender] = true;
        thisReq.noOfVoters++;
    }

    function makePayment(uint256 _requestNo) public onlyManager {
        require(raisedAmount >= target);
        Request storage thisReq = requests[_requestNo];
        require(thisReq.completed == false, "The request has been completed");
        require(
            thisReq.noOfVoters > noOfContributors / 2,
            "Majority peoples are not in support"
        );
        thisReq.recipient.transfer(thisReq.requiredFund);
        thisReq.completed = true;
    }
}
