// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

contract FreelancingPlatform {
    ////// Enums //////
    enum JobStatus { Open, Taken, Completed, Cancelled }





    ////// Structs //////
    struct Job {
        string job_title;
        string job_description;
        uint256 job_budget;
        uint256 job_deadline;
        address client;
        address freelancer;
        JobStatus status;
    }




    ////// Constants & State Variables //////
    uint256 public constant REPUTATION_REWARD = 1;
    uint256 public listingFee = 0.001 ether;
    address public owner;
    uint256 public TotalJobs;



    ////// Mappings //////
    mapping(uint256 => Job) public Jobs;
    mapping(address => uint256) public freelancerReputation;



    ////// Events //////
    event JobCreated(uint256 indexed jobId, uint256 budget, address indexed client);
    event JobTaken(uint256 indexed jobId, address indexed freelancer);
    event JobCompleted(uint256 indexed jobId, address indexed freelancer);




    ////// Errors //////
    error NotEnoughFunds();




    ////// Modifiers //////
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }




    ////// Functions //////
    constructor() {
        owner = msg.sender;
    }

    function PostJob(string calldata _title, string calldata _description, uint _deadline) external payable {
        if (msg.value < listingFee) {
            revert NotEnoughFunds();
}
        TotalJobs++;
        Jobs[TotalJobs] = Job({
            job_title: _title,
            job_description: _description,
            job_budget: msg.value - listingFee,
            job_deadline: _deadline,
            client: msg.sender,
            freelancer: address(0),
            status: JobStatus.Open
        });

        emit JobCreated(TotalJobs, msg.value - listingFee, msg.sender);
    }

    function getAllJobs() external view returns (Job[] memory) {
        Job[] memory allJobs = new Job[](TotalJobs);
        for (uint256 i = 1; i <= TotalJobs; i++) {
            allJobs[i - 1] = Jobs[i];
        }
        return allJobs;
    }

    function acceptJob(uint256 _jobId) external {
        Job storage job = Jobs[_jobId];
        require(job.status == JobStatus.Open, "Not Available");
        require(msg.sender != job.client, "Client cannot be freelancer");
        
        job.status = JobStatus.Taken;
        job.freelancer = msg.sender;
        emit JobTaken(_jobId, msg.sender);
        
    }

    function completeJob(uint256 _jobId) external {
        Job storage job = Jobs[_jobId];
        require(msg.sender == job.client, "Not the client");
        require(job.status == JobStatus.Taken, "Job available");

        job.status = JobStatus.Completed;
        freelancerReputation[job.freelancer] += REPUTATION_REWARD;
        emit JobCompleted(_jobId, job.freelancer);
        (bool success, ) = payable (job.freelancer).call{value: job.job_budget}(bytes(""));
        require(success, "Transfer failed");
}

    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
    }

    function getPlatformBalance() external view returns ( uint256 ) {
        return address(this).balance;
    } 


}