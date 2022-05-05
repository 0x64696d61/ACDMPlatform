import {expect} from "chai";
import {ethers, network} from "hardhat";
import {BigNumber, Contract} from "ethers";
import {expandTo18Decimals, expandTo6Decimals} from './shared/utils'

const contractName = "ACDMPlatform"

describe(contractName, function () {
    const overrides = {
        gasLimit: 9999999
    }
    let acc1: any
    let acc2: any
    let acc3: any
    let contractACDMPlatform: Contract
    let contractStaking: Contract
    let contractDao: Contract
    let lpToken: Contract
    let xxxToken: Contract
    let acdmToken: Contract

    const tokenValue = 100_000_000000
    let percentFirstReferralLevel: any
    let percentSecondReferralLevel: any

    beforeEach(async function () {

        [acc1, acc2, acc3] = await ethers.getSigners()
        const chairMan = acc1.address

        let factory = await ethers.getContractFactory("XXXToken", acc1)
        xxxToken = await factory.deploy()

        factory = await ethers.getContractFactory("ERC20Mock", acc1)
        lpToken = await factory.deploy("LP Token", "ACDMLP", 5555 * 10 ** 6)

        factory = await ethers.getContractFactory("ACDMToken", acc1)
        acdmToken = await factory.deploy();

        factory = await ethers.getContractFactory("ACDMStaking", acc1)
        contractStaking = await factory.deploy(lpToken.address, acdmToken.address);
        lpToken.approve(contractStaking.address, lpToken.totalSupply())

        factory = await ethers.getContractFactory("ACDMDao", acc1)
        contractDao = await factory.deploy(chairMan, contractStaking.address, "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", 0, 3600);

        contractStaking.setDao(contractDao.address)

        factory = await ethers.getContractFactory(contractName, acc1)
        contractACDMPlatform = await factory.deploy(acdmToken.address, contractDao.address);

        acdmToken.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes('MINTER_ROLE')), contractACDMPlatform.address)
        contractACDMPlatform.startPlatform();

        // get configure referrals level percent
        percentFirstReferralLevel = await contractACDMPlatform.percentFirstReferralLevel()
        percentSecondReferralLevel = await contractACDMPlatform.percentSecondReferralLevel()
    })

    // it("Should be deployed", async function () {
    //     expect(contractACDMPlatform.address).to.be.properAddress
    //
    // })
    // describe("Selling round", function () {
    //
    //     describe("buyToken method", function () {
    //         it("User should be can buyToken tokens", async function () {
    //             let beforeBalanceACMDToken = await acdmToken.balanceOf(acc1.address)
    //             const tx = await contractACDMPlatform.buyToken({value: ethers.constants.WeiPerEther})
    //
    //             expect(await expect(() => tx).to.changeEtherBalance(acc1, BigInt(-ethers.constants.WeiPerEther)))
    //             expect(await acdmToken.balanceOf(acc1.address)).to.be.equal(beforeBalanceACMDToken.add(tokenValue))
    //             expect(await acdmToken.balanceOf(contractACDMPlatform.address)).to.be.equal(0)
    //
    //         })
    //     })
    // })
    //
    // describe("Trading round", function () {
    //
    //     beforeEach(async function () {
    //         await contractACDMPlatform.buyToken({value: ethers.constants.WeiPerEther})
    //         await contractACDMPlatform.closeSellingRound()
    //         await acdmToken.approve(contractACDMPlatform.address, ethers.constants.WeiPerEther)
    //         await contractACDMPlatform.createOrder(tokenValue, ethers.constants.WeiPerEther)
    //     })
    //
    //     describe("createOrder method", function () {
    //         it("User should be can Create order to sell tokens", async function () {
    //             expect(await acdmToken.balanceOf(acc1.address)).to.be.equal(0)
    //         })
    //     })
    //
    //     describe("buyOrder method", function () {
    //         it("User should be can Buy order", async function () {
    //             const tx = await contractACDMPlatform.connect(acc2).buyOrder(0, {value: ethers.constants.WeiPerEther})
    //             const FirstReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentFirstReferralLevel)
    //             const SecondReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentSecondReferralLevel)
    //             const treasuryReward = FirstReferralValue + SecondReferralValue
    //
    //             expect(await expect(() => tx).to.changeEtherBalance(acc1, ethers.constants.WeiPerEther.toBigInt() - treasuryReward))
    //             expect(await acdmToken.balanceOf(acc2.address)).to.be.equal(tokenValue)
    //         })
    //         it("Trying buy not existed order", async function () {
    //             await expect(contractACDMPlatform.buyOrder(999, {value: ethers.constants.WeiPerEther})).to.be.revertedWith("Order not exist")
    //         })
    //     })
    //     describe("cancelOrder method", function () {
    //
    //         it("User should be can cancel order", async function () {
    //             await contractACDMPlatform.cancelOrder(0)
    //             await expect(contractACDMPlatform.cancelOrder(0)).to.be.revertedWith("Permission denied")
    //         })
    //     })
    //
    // })
    //
    // describe("Referral checking", function () {
    //     beforeEach(async function () {
    //         await contractACDMPlatform.connect(acc3).buyToken({value: ethers.constants.WeiPerEther})
    //         await acdmToken.connect(acc3).approve(contractACDMPlatform.address, ethers.constants.WeiPerEther)
    //         await contractACDMPlatform.closeSellingRound()
    //
    //     })
    //
    //     it("All referrals should get reward", async function () {
    //         await contractACDMPlatform.connect(acc1).userRegistration()
    //         await contractACDMPlatform.connect(acc2).userRegistrationWithsReferral(acc1.address)
    //         await contractACDMPlatform.connect(acc3).userRegistrationWithsReferral(acc2.address)
    //
    //
    //         await contractACDMPlatform.connect(acc3).createOrder(tokenValue, ethers.constants.WeiPerEther)
    //         const tx = await contractACDMPlatform.connect(acc3).buyOrder(0, {value: ethers.constants.WeiPerEther})
    //
    //         const FirstReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentFirstReferralLevel)
    //         const SecondReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentSecondReferralLevel)
    //         expect(await expect(() => tx).to.changeEtherBalances([acc2, acc1], [FirstReferralValue, SecondReferralValue]))
    //     })
    //
    //     it("Treasury should get reward", async function () {
    //
    //         await contractACDMPlatform.connect(acc3).createOrder(tokenValue, ethers.constants.WeiPerEther)
    //         const tx = await contractACDMPlatform.connect(acc3).buyOrder(0, {value: ethers.constants.WeiPerEther})
    //
    //         const FirstReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentFirstReferralLevel)
    //         const SecondReferralValue = BigInt(1_000_000_000_000_000_000 / 100 * percentSecondReferralLevel)
    //
    //         const treasuryReward = FirstReferralValue + SecondReferralValue
    //         expect(await ethers.provider.getBalance(contractDao.address)).to.be.eq(treasuryReward)
    //     })
    // })

//       // https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
    describe("Dao voting for treasury", function () {
        function getCallData() {
            const jsonAbi = [{
                "inputs": [
                    {
                        "internalType": "address",
                        "name": "owner",
                        "type": "address"
                    },
                    {
                        "internalType": "address",
                        "name": "tokenAddress",
                        "type": "address"
                    }
                ],
                "name": "stealTreasury",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            }
            ];
            const iface = new ethers.utils.Interface(jsonAbi);
            return iface.encodeFunctionData('stealTreasury', [acc1.address, acdmToken.address]);
        }

        beforeEach(async function () {
            await contractACDMPlatform.buyToken({value: ethers.constants.WeiPerEther})
            await acdmToken.approve(contractACDMPlatform.address, ethers.constants.MaxUint256)
            await contractACDMPlatform.closeSellingRound()
            await contractACDMPlatform.createOrder(tokenValue, ethers.constants.WeiPerEther)
            await contractACDMPlatform.buyOrder(0, {value: ethers.constants.WeiPerEther})
            // Earning eth :)
            await contractACDMPlatform.createOrder(tokenValue, ethers.constants.WeiPerEther)
            await contractACDMPlatform.buyOrder(1, {value: ethers.constants.WeiPerEther})
            await contractACDMPlatform.createOrder(tokenValue, ethers.constants.WeiPerEther)
            await contractACDMPlatform.buyOrder(2, {value: ethers.constants.WeiPerEther})


        })
        it("Make swap for stealTreasury", async function () {


            let router = await ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
            let factory = await ethers.getContractAt("IUniswapV2Factory", router.factory())
            // let pairAddress = factory.getPair(tokenAddr, router.WETH())
            // let pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress)

            let tokenAddr = acdmToken.address
            let tokenAmount = expandTo6Decimals(100000)
            let ethAmount = ethers.utils.parseEther("1.0")
            acdmToken.approve(router.address, acdmToken.totalSupply())

            await factory.createPair(tokenAddr, router.WETH())
            await router.addLiquidityETH(
                tokenAddr,
                tokenAmount,
                tokenAmount,
                ethAmount,
                acc1.address,
                ethers.constants.MaxUint256,
                {...overrides, value: ethAmount})


            await contractStaking.stake(1000)
            await contractDao.addProposal(getCallData(), contractDao.address, "Send reward to ?!")
            await contractDao.vote(0, true)
            await network.provider.send("evm_increaseTime", [3600])
            await contractDao.finishProposal(0)

            // await router.swapExactETHForTokens(
            //     0,
            //     [router.WETH(), tokenAddr],
            //     acc1.address,
            //     ethers.constants.MaxUint256,
            //     {...overrides, value: ethers.utils.parseEther("1.0")}
            // );

            //await contractDao.stealTreasury(acc1.address, acdmToken.address)
            console.log(await acdmToken.balanceOf(acc1.address))

            expect(await acdmToken.balanceOf(acc1.address)).to.be.eq(19307985281)
        })

    })
});
