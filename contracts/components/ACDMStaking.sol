// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ACDMDao.sol";
import "../interfaces/IACDMToken.sol";

contract ACDMStaking is AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    IERC20 private _stakingToken;
    IACDMToken private _rewardToken;
    ACDMDao private _acdmDao;

    uint8 public stakingPercent = 3;
    uint public unstakeFrozenTime = 10 days;
    uint public stakingRewardTime = 7 days;

    event Stake(address indexed account, uint256 amount);
    event Reward(address indexed account, uint256 amount);

    struct User
    {
        uint startTime;
        uint stakingBalance;
    }

    constructor(address stakingTokenAddress, address rewardTokenAddress) {
        _stakingToken = IERC20(stakingTokenAddress);
        _rewardToken = IACDMToken(rewardTokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(address => User) private _users;

    modifier userExist(){
        require(_users[msg.sender].stakingBalance > 0, "User not exist");
        _;
    }
    modifier checkTime(uint time) {
        require(block.timestamp >= _users[msg.sender].startTime + time, "It's too soon. Try later");
        _;
    }

    function stake(uint amount) external {
        require(amount > 100, "amount will be more");

        if (reward() > 0)
            claim();
        _stakingToken.transferFrom(msg.sender, address(this), amount);
        _users[msg.sender].stakingBalance += amount;
        _users[msg.sender].startTime = block.timestamp;
        emit Stake(msg.sender, amount);
    }

    function claim() public userExist checkTime(stakingRewardTime) {

        uint amount = reward();
        _rewardToken.transfer(msg.sender, amount);
        _users[msg.sender].startTime = block.timestamp;
        emit Reward(msg.sender, amount);
    }

    function unstake() external userExist checkTime(unstakeFrozenTime) {
        require(address(_acdmDao) != address(0));
        require(_acdmDao.getUserLockTime(msg.sender) < block.timestamp, "Time for a vote is not up");

        claim();
        _stakingToken.transfer(msg.sender, _users[msg.sender].stakingBalance);
        _users[msg.sender].stakingBalance = 0;
    }

    function reward() private view returns (uint) {
        uint different = (block.timestamp - _users[msg.sender].startTime) / stakingRewardTime;
        uint rate = _users[msg.sender].stakingBalance / 100 * stakingPercent;
        uint _reward = rate * different;
        return _reward;
    }

    function changePercent(uint8 percent) external onlyRole(DAO_ROLE) {
        stakingPercent = percent;
    }

    function changeFrozenTime(uint time) external onlyRole(DAO_ROLE) {
        unstakeFrozenTime = time;
    }

    function getStakeBalance(address user) external view returns (uint){
        return _users[user].stakingBalance;
    }

    function setDao(address payable daoContractAddress) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _acdmDao = ACDMDao(daoContractAddress);
        _grantRole(DAO_ROLE, daoContractAddress);
    }

}
