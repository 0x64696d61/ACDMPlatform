// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XXXToken is ERC20 {

    constructor() ERC20("XXXXToken", 'XXXX') {
        _mint(msg.sender, 10_000 * 10 ** 18);
    }

}