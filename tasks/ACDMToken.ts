import {task} from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import {ethers} from "hardhat";
import {BytesLike} from "@ethersproject/bytes"

const contract_name = 'ACDMToken'
const prefix = contract_name + '_'

task(prefix + "mint", "mint")
    .addParam("address", "Contract address")
    .addParam("toAddress", "toAddress")
    .addParam("amount", "amount")

    .setAction(async (taskArgs, hre) => {
        const [acc1] = await hre.ethers.getSigners()
        const factory = await hre.ethers.getContractFactory(contract_name);
        const contract = await factory.attach(taskArgs.address)
        await contract.mint(taskArgs.toAddress, taskArgs.amount)
    });


