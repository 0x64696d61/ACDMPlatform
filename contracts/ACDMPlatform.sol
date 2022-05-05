// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./components/ACDMDao.sol";

import "./interfaces/IACDMToken.sol";
//import "./interfaces/IACDMDao.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";


contract ACDMPlatform is ReentrancyGuard, AccessControl {
    bytes32 private constant DAO_ROLE = keccak256("DAO_ROLE");
    uint tradingRoundTime = 1 days;
    uint sellingRoundTime = 3 days;
    uint8 public percentFirstReferralLevel = 5;
    uint8 public percentSecondReferralLevel = 3;
    uint8 currentRound;
    uint private _orderId;
    ACDMDao public acdmDaoContract;
    IACDMToken public acdmToken;

    enum RoundPart {tradingRound, sellingRound}
    RoundPart currentRoundPart;

    constructor(address acdmTokenAddress, address payable daoContractAddress) {
        _grantRole(DAO_ROLE, daoContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        acdmToken = IACDMToken(acdmTokenAddress);
        acdmDaoContract = ACDMDao(daoContractAddress);
    }

    struct Round {
        uint price;
        uint startTime;
        uint tradingRoundVolume;
    }

    struct Item {
        uint price;
        uint baseTokenAmount;
        address owner;
    }

    struct User {
        bool status;
        address referral;
    }

    mapping(uint => Round) rounds;
    mapping(uint => Item) public orderBook;
    mapping(address => User) users;


    modifier checkTime(uint time) {
        require(block.timestamp >= rounds[currentRound].startTime + time, "It's too soon. Try later");
        _;
    }
    modifier onlyTradingRound() {
        require(currentRoundPart == RoundPart.tradingRound, "This is NO trading round");

        _;
    }
    modifier onlySellingRound() {
        require(currentRoundPart == RoundPart.sellingRound, "This is NO selling round");
        _;
    }

    function startPlatform() external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(rounds[0].startTime == 0, "Possible only once");
        initRoundPrice();
        startSellingRound();
    }

    function buyToken() payable external onlySellingRound() nonReentrant()
    {
        uint tryBuyTokens = (msg.value / rounds[currentRound].price);

        require(tryBuyTokens <= rounds[currentRound].tradingRoundVolume, "We don't have that many tokens");
        require(msg.value >= rounds[currentRound].price, "Minimum one token");

        rounds[currentRound].tradingRoundVolume -= tryBuyTokens;
        acdmToken.transfer(msg.sender, tryBuyTokens);
    }

    function closeSellingRound() external onlySellingRound()
    {
        if (rounds[currentRound].tradingRoundVolume > 0)
            require(block.timestamp >= rounds[currentRound].startTime + sellingRoundTime, "It's too soon. Try later");

        acdmToken.burn(rounds[currentRound].tradingRoundVolume);
        currentRound += 1;
        startTradingRound();
    }

    function closeTradingRound() external onlyTradingRound() checkTime(tradingRoundTime)
    {
        startSellingRound();
    }

    function createOrder(uint baseTokenAmount, uint quoteTokenAmount) external onlyTradingRound() nonReentrant()
    {
        acdmToken.transferFrom(msg.sender, address(this), baseTokenAmount);
        orderBook[_orderId].owner = msg.sender;
        orderBook[_orderId].baseTokenAmount = baseTokenAmount;
        orderBook[_orderId].price = quoteTokenAmount / baseTokenAmount;
        _orderId += 1;
    }

    function buyOrder(uint orderId) payable external onlyTradingRound()
    {
        require(orderBook[orderId].price > 0, "Order not exist");
        require(msg.value >= orderBook[orderId].price, "Minimum one token for sale");

        uint amount = msg.value / orderBook[orderId].price;

        require(orderBook[orderId].baseTokenAmount >= amount, "There aren't that many tokens");

        orderBook[orderId].baseTokenAmount -= amount;
        rounds[currentRound].tradingRoundVolume += amount;
        uint ethAmountAfterShare = shareEthWithReferrals(orderBook[orderId].owner, msg.value);
        payable(orderBook[orderId].owner).transfer(ethAmountAfterShare);
        acdmToken.transfer(msg.sender, amount);
    }

    function cancelOrder(uint orderId) external onlyTradingRound()
    {
        require(orderBook[orderId].owner == msg.sender, "Permission denied");

        acdmToken.transfer(msg.sender, orderBook[orderId].baseTokenAmount);
        delete orderBook[orderId];
    }

    function userRegistration() external
    {
        users[msg.sender].status = true;
    }

    function userRegistrationWithsReferral(address referral) external
    {
        require(users[referral].status == true, "This referral dont exist");

        users[msg.sender].status = true;
        users[msg.sender].referral = referral;
    }

    function shareEthWithReferrals(address owner, uint value) private returns (uint)
    {
        uint referralFirstAmount = value / 100 * percentFirstReferralLevel;
        uint referralSecondAmount = value / 100 * percentSecondReferralLevel;
        address referralFirstAddress = users[owner].referral;
        address referralSecondAddress = users[users[owner].referral].referral;

        sendToReferralOrDao(referralFirstAddress, referralFirstAmount);
        sendToReferralOrDao(referralSecondAddress, referralSecondAmount);

        return (value - referralFirstAmount - referralSecondAmount);
    }

    function sendToReferralOrDao(address addressReferral, uint amount) private
    {
        if (addressReferral != address(0))
            payable(addressReferral).transfer(amount);
        else
            payable(address(acdmDaoContract)).transfer(amount);
    }

    function changeReferralPercent(uint8 referralLevel, uint8 percent) external onlyRole(DAO_ROLE)
    {
        if (referralLevel == 0)
            percentFirstReferralLevel = percent;
        else
            percentSecondReferralLevel = percent;
    }

    function startSellingRound() private
    {
        if (rounds[currentRound].price == 0)
            rounds[currentRound].price = rounds[currentRound - 1].price / 100 * 3 + 4000000000000;

        currentRoundPart = RoundPart.sellingRound;
        acdmToken.mint(address(this), rounds[currentRound].tradingRoundVolume);
        rounds[currentRound].startTime = block.timestamp;
    }

    function startTradingRound() private
    {
        currentRoundPart = RoundPart.tradingRound;
        rounds[currentRound].startTime = block.timestamp;
    }

    function initRoundPrice() private
    {
        rounds[0].price = 10_000_000_000_000 / 10 ** acdmToken.decimals();
        rounds[0].tradingRoundVolume = (1 ether / rounds[0].price);
    }

}
