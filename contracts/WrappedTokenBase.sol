// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedLnbgLondon is ERC20, Ownable {
    address public bridge;

    constructor(
        string memory name,
        string memory symbol,
        address _bridge
    ) ERC20(name, symbol) {
        bridge = _bridge;
    }

    function updatebridge(address _newbridge) external onlyOwner {
        bridge = _newbridge;
    }

    function mint(address _to, uint _amount) external {
        require(msg.sender == bridge, "only bridge");
        _mint(_to, _amount);
    }

    function burn(address _owner, uint _amount) external {
        require(msg.sender == bridge, "only bridge");
        _burn(_owner, _amount);
    }
}
