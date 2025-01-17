// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LnbgLondonCoinBridgeBase is Ownable {
    address public adminValut;
    address public lnbgVault;
    uint256 public contractNonce;

    IERC20 public token;

    event LockDeposits(
        address from,
        address to,
        address vault,
        uint amount,
        uint date,
        uint nonce,
        uint chainId
    );

    event unLockDeposits(
        address from,
        address to,
        uint amount,
        uint date,
        uint nonce,
        uint chainId
    );

    mapping(uint256 => mapping(uint256 => bool)) public processedNonces;

    constructor(address _token) {
        token = IERC20(_token);
        lnbgVault = address(this);
        adminValut = msg.sender;
    }

    function updateAdmin(address _newAdmin) external onlyOwner {
        adminValut = _newAdmin;
    }

    function depositTokenFor(
        address _from,
        address _to,
        uint _amount,
        uint _chainId
    ) external {
        token.transferFrom(_from, lnbgVault, _amount);
        emit LockDeposits(
            _from,
            _to,
            lnbgVault,
            _amount,
            block.timestamp,
            contractNonce,
            _chainId
        );
        contractNonce++;
    }

    function requestedTokensFor(
        address _to,
        uint _amount,
        uint _nonce,
        uint chainId
    ) external {
        require(msg.sender == adminValut, "only Admin");
        require(
            processedNonces[chainId][_nonce] == false,
            "transfer already processed"
        );
        processedNonces[chainId][_nonce] = true;
        token.transfer(_to, _amount);
        emit unLockDeposits(
            lnbgVault,
            _to,
            _amount,
            block.timestamp,
            _nonce,
            chainId
        );
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        token.transfer(owner(), _amount);
    }
}
