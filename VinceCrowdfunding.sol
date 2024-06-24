// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract VinceCrowdfunding{
    address public projectBeneficiary;
    uint256 public totalRaised;
    uint256 public goalAmount;
    uint256 public campaignDeadline;
    bool public campaignOpen;
    mapping(address => uint256) public pledges;

    event PledgeReceived(address contributor, uint256 amount);
    event CampaignFinalized(address beneficiary, uint256 totalAmountRaised);

    constructor(address _projectBeneficiary, uint256 _goalAmount, uint256 _campaignDurationInMinutes){
        require(_projectBeneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_goalAmount > 0, "Funding goal must be greater than zero.");
        require(_campaignDurationInMinutes > 0, "Duration must be greater than zero.");

        projectBeneficiary = _projectBeneficiary;
        goalAmount = _goalAmount;
        campaignDeadline = block.timestamp + (_campaignDurationInMinutes * 1 minutes);
        campaignOpen = true;
    }

    function pledge() external payable {
        require(campaignOpen, "Campaign is closed.");
        require(block.timestamp <= campaignDeadline, "Campaign deadline has passed.");
        require(msg.value >= 0, "Pledge must be greater than zero.");

        pledges[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit PledgeReceived(msg.sender, msg.value);
    }

    function checkGoalMet() public view returns (bool) {
        return totalRaised >= goalAmount;
    }

     function finalizeCampaign() external {
        require(block.timestamp >= campaignDeadline, "Campaign is still running.");
        require(campaignOpen, "Campaign has already ended.");

        campaignOpen = false;

        if (totalRaised >= goalAmount) {
            bool success = false;
            (success, ) = projectBeneficiary.call{value: totalRaised}("");
            assert(success); // assert transfer was successful
            emit CampaignFinalized(projectBeneficiary, totalRaised);
        } else {
            revert("Funding goal not reached, pledges can be withdrawn by contributors.");
        }
    }

    function withdrawPledge() external {
        require(!campaignOpen, "Campaign is still open.");
        require(totalRaised < goalAmount, "Funding goal was reached, cannot withdraw.");

        uint256 pledgedAmount = pledges[msg.sender];
        require(pledgedAmount > 0, "No pledges to withdraw.");

        pledges[msg.sender] = 0;
        bool success = false;
        (success, ) = payable(msg.sender).call{value: pledgedAmount}("");
        require(success, "Withdrawal failed.");
    }

}
