import {ethers} from "hardhat";

const contract_name = 'Dao'
const usdcToken = '0x58c391bfCf7C7aEf634052F4A41a79488Fe6A51F'
const chairMan = '0x7620B8FC45f0F445471Aa9534C3836d290CC6d93'
const lpToken = '0x44c89cc774Ba4550138cF746f37709F0B4FAE1f7'
const uniswapRouter = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'
const minimumQuorum = 2
const debatingPeriodDuration = 3600


async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);



    let factory = await ethers.getContractFactory("ACDMToken")
    const acdmToken = await factory.deploy();
    console.log("Contract deployed to:", acdmToken.address);


    factory = await ethers.getContractFactory("ACDMStaking")
    const contractStaking = await factory.deploy(lpToken, acdmToken.address);

    factory = await ethers.getContractFactory("ACDMDao")
    const contractDao = await factory.deploy(chairMan, contractStaking.address, uniswapRouter, minimumQuorum, debatingPeriodDuration);

    contractStaking.setDao(contractDao.address)

    factory = await ethers.getContractFactory("ACDMPlatform")
    const contractACDMPlatform = await factory.deploy(acdmToken.address, contractDao.address);

    acdmToken.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes('MINTER_ROLE')), contractACDMPlatform.address)
    contractACDMPlatform.startPlatform();

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });