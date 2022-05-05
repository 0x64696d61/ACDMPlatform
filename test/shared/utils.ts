import {ethers, network} from "hardhat";
import {BigNumber} from 'ethers';

export function expandTo18Decimals(n: number): BigNumber {
    return ethers.BigNumber.from(n).mul(ethers.BigNumber.from(10).pow(18))
}

export function expandTo6Decimals(n: number): BigNumber {
    return ethers.BigNumber.from(n).mul(ethers.BigNumber.from(10).pow(6))
}
