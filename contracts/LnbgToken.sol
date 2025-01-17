//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LnbgLondonCoin is ERC20, Ownable {
    constructor() ERC20("LnbgLondonCoin", "$LLC") Ownable() {
        _mint(msg.sender, 7000000000 * 10 ** decimals());
    }
}
