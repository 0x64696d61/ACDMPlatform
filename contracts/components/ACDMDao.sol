// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ACDMStaking.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint) external;
}

contract ACDMDao {
    address public chairMan;
    uint private _minimumQuorum;
    uint public debatingPeriodDuration;
    uint private _proposalNumber;
    ACDMStaking private stakingContract;
    IUniswapV2Router02 private router;


    event resultProposal(uint id, bool status);
    event newProposal(uint id, string description);
    event userWithdrawal(address sender, uint256 amount);
    event userVote(address voterAddress, bool newVote);

    struct User {
        uint frozenTime;
    }

    struct Proposal {
        string description;
        bytes callData;
        address recipient;
        int votes;
        uint endDate;
        uint votedCounter;
        bool result;
        bool status;
    }

    mapping(address => User) private users;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) private votes;


    constructor(address _chairMan, address stakingContractAddress, address UniswapV2Router02Address, uint minimumQuorum, uint _debatingPeriodDuration) {
        chairMan = _chairMan;
        stakingContract = ACDMStaking(stakingContractAddress);
        _minimumQuorum = minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
        router = IUniswapV2Router02(UniswapV2Router02Address);
    }


    function addProposal(bytes memory callData, address recipient, string memory description) external
    {
        require(msg.sender == chairMan, "Permission denied");

        proposals[_proposalNumber].description = description;
        proposals[_proposalNumber].callData = callData;
        proposals[_proposalNumber].recipient = recipient;
        proposals[_proposalNumber].endDate = block.timestamp + debatingPeriodDuration;
        emit newProposal(_proposalNumber, proposals[_proposalNumber].description);
        _proposalNumber += 1;
    }

    function vote(uint proposalId, bool choice) external
    {
        require(proposals[proposalId].endDate > block.timestamp, "This proposal is not found or has already been completed");
        require(votes[proposalId][msg.sender] == false, "You already voted");
        require(stakingContract.getStakeBalance(msg.sender) > 0, "Please stake LP tokens before");

        if (users[msg.sender].frozenTime < proposals[proposalId].endDate)
            users[msg.sender].frozenTime = proposals[proposalId].endDate;
        if (choice)
            proposals[proposalId].votes += int(stakingContract.getStakeBalance(msg.sender));
        else
            proposals[proposalId].votes -= int(stakingContract.getStakeBalance(msg.sender));

        proposals[proposalId].votedCounter += 1;
        votes[proposalId][msg.sender] = true;
        emit userVote(msg.sender, choice);
    }


    function finishProposal(uint proposalId) external
    {
        require(proposals[proposalId].status == false, "This proposal has been already closed");
        require(block.timestamp > proposals[proposalId].endDate, "Time for a vote is not up");

        if (proposals[proposalId].votes > 0 && proposals[proposalId].votedCounter >= _minimumQuorum)
        {
            runProposal(proposalId);
            proposals[proposalId].result = true;
        }
        else
            proposals[proposalId].result = false;
        proposals[proposalId].status = true;
        emit resultProposal(proposalId, proposals[proposalId].result);
    }

    function runProposal(uint proposalId) private
    {
        (bool success,) = proposals[proposalId].recipient.call{value : 0}(proposals[proposalId].callData);
        require(success, "ERROR call func");
    }

    function getUserLockTime(address user) external view returns (uint)
    {
        return users[user].frozenTime;
    }

    function stealTreasury(address owner, address tokenAddress) external
    {
        require(msg.sender == address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;

        router.swapExactETHForTokens{value : address(this).balance}(0, path, owner, block.timestamp);
    }

    receive() external payable {}

}