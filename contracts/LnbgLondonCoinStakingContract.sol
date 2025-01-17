// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LnbgLondonCoinStakingContract is Ownable, ReentrancyGuard {
    uint256 public totalStakedTokens;
    uint256 public totalClaimedTokens;

    uint256 public totalInvestors;
    uint256 public reward;

    struct Stake {
        uint256 stakedTokens;
        uint256 startTime;
        uint256 duration;
        address stakedTokenAddress;
    }

    IERC20 public lnbgToken;
    IERC20 public usdtToken;
    IERC20 public usdcToken;
    IERC20 public wethToken;
    IERC20 public wbtcToken;
    IERC20 public wbnbToken;

    // Use nested mapping
    mapping(address => mapping(address => Stake)) public userStakesByToken;
    mapping(address => bool) public investor;
    mapping(address => uint256) public claimedRewards;

    address[] public investorAddresses;

    event Staked(address indexed by, uint256 amount, address token);
    event Withdrawn(address indexed by, uint256 amount, address token);

    constructor(
        address _lnbgToken,
        address _usdtToken,
        address _usdcToken,
        address _wethToken,
        address _wbtcToken,
        address _wbnbToken
    ) {
        lnbgToken = IERC20(_lnbgToken);
        usdtToken = IERC20(_usdtToken);
        usdcToken = IERC20(_usdcToken);
        wethToken = IERC20(_wethToken);
        wbtcToken = IERC20(_wbtcToken);
        wbnbToken = IERC20(_wbnbToken);
        reward = 10; // 10%
    }

    function setAnnualRewardPercentage(uint256 _percentage) public onlyOwner {
        reward = _percentage; // 1 = 1%
    }

    function rewardedTokens(
        address _user,
        address _token
    ) public view returns (uint256) {
        Stake memory stakingDetails = userStakesByToken[_user][_token];
        uint256 totalTime = block.timestamp - stakingDetails.startTime;
        uint256 totalRewards = rewardRateInSeconds(_user, _token) * totalTime;
        return totalRewards;
    }

    function rewardRateInSeconds(
        address _user,
        address _token
    ) public view returns (uint256) {
        Stake memory stakingDetails = userStakesByToken[_user][_token];
        return ((stakingDetails.stakedTokens * reward) / 100) / 31536000; // reward rate per second
    }

    function stakeTokens(
        uint256 _tokens,
        uint256 _duration,
        address _token
    ) public nonReentrant {
        require(_tokens > 0, "Amount cannot be 0");
        require(
            _duration > (block.timestamp + 89 days),
            "Please stake for at least 90 days"
        );
        IERC20 tokenContract = _getTokenContract(_token);
        require(
            tokenContract.balanceOf(msg.sender) >= _tokens,
            "Insufficient balance for staking"
        );

        tokenContract.transferFrom(msg.sender, address(this), _tokens);

        Stake storage existingStake = userStakesByToken[msg.sender][_token];
        if (existingStake.stakedTokens > 0) {
            existingStake.stakedTokens += _tokens;
            existingStake.duration = _duration;
            existingStake.startTime = block.timestamp;
        } else {
            userStakesByToken[msg.sender][_token] = Stake({
                stakedTokens: _tokens,
                startTime: block.timestamp,
                duration: _duration,
                stakedTokenAddress: _token
            });

            if (!investor[msg.sender]) {
                investor[msg.sender] = true;
                totalInvestors++;
                investorAddresses.push(msg.sender);
            }
        }
        totalStakedTokens += _tokens;
        emit Staked(msg.sender, _tokens, _token);
    }

    function unstakeTokensRequest(address _token) public nonReentrant {
        Stake storage userStake = userStakesByToken[msg.sender][_token];
        require(userStake.stakedTokens > 0, "No stakes found for this address");
        require(
            block.timestamp > userStake.duration,
            "Cannot unstake before staking duration ends"
        );
        uint256 stakedTokensAmount = userStake.stakedTokens;
        uint256 rewardedToken = rewardedTokens(msg.sender, _token);

        claimedRewards[msg.sender] += rewardedToken;
        totalClaimedTokens += rewardedToken;
        totalStakedTokens -= stakedTokensAmount;

        delete userStakesByToken[msg.sender][_token];

        IERC20 tokenContract = IERC20(_token);
        tokenContract.transfer(msg.sender, stakedTokensAmount);
        lnbgToken.transfer(msg.sender, rewardedToken);

        if (!hasActiveStakes(msg.sender)) {
            investor[msg.sender] = false;
            totalInvestors--;
        }

        emit Withdrawn(msg.sender, stakedTokensAmount, _token);
    }

    function hasActiveStakes(address _user) public view returns (bool) {
        return
            userStakesByToken[_user][address(lnbgToken)].stakedTokens > 0 ||
            userStakesByToken[_user][address(usdtToken)].stakedTokens > 0 ||
            userStakesByToken[_user][address(usdcToken)].stakedTokens > 0 ||
            userStakesByToken[_user][address(wethToken)].stakedTokens > 0 ||
            userStakesByToken[_user][address(wbtcToken)].stakedTokens > 0 ||
            userStakesByToken[_user][address(wbnbToken)].stakedTokens > 0;
    }

    function withdrawTokens(uint256 _amount, address _token) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function changeTokenAddress(
        address _lnbgToken,
        address _usdtToken,
        address _usdcToken,
        address _wethToken,
        address _wbtcToken,
        address _wbnbToken
    ) public onlyOwner {
        require(
            _lnbgToken != address(0) &&
                _usdtToken != address(0) &&
                _usdcToken != address(0) &&
                _wethToken != address(0) &&
                _wbtcToken != address(0) &&
                _wbnbToken != address(0),
            "Zero Address"
        );

        lnbgToken = IERC20(_lnbgToken);
        usdtToken = IERC20(_usdtToken);
        usdcToken = IERC20(_usdcToken);
        wethToken = IERC20(_wethToken);
        wbtcToken = IERC20(_wbtcToken);
        wbnbToken = IERC20(_wbnbToken);
    }

    function getAllInvestors() public view returns (address[] memory) {
        return investorAddresses;
    }

    function _getTokenContract(address _token) internal view returns (IERC20) {
        if (_token == address(lnbgToken)) {
            return lnbgToken;
        } else if (_token == address(usdtToken)) {
            return usdtToken;
        } else if (_token == address(usdcToken)) {
            return usdcToken;
        } else if (_token == address(wethToken)) {
            return wethToken;
        } else if (_token == address(wbtcToken)) {
            return wbtcToken;
        } else if (_token == address(wbnbToken)) {
            return wbnbToken;
        } else {
            revert("Invalid token address");
        }
    }

    // Function to get total earned tokens for all users
    function getTotalEarnings() public view returns (uint256) {
        uint256 totalEarnings = 0; // Variable to store total earnings

        for (uint256 i = 0; i < investorAddresses.length; i++) {
            address user = investorAddresses[i];
            // Sum up earned tokens for LNBG, USDT, and USDC
            totalEarnings += rewardedTokens(user, address(lnbgToken));
            totalEarnings += rewardedTokens(user, address(usdtToken));
            totalEarnings += rewardedTokens(user, address(usdcToken));
            totalEarnings += rewardedTokens(user, address(wethToken));
            totalEarnings += rewardedTokens(user, address(wbtcToken));
            totalEarnings += rewardedTokens(user, address(wbnbToken));
        }

        return totalEarnings; // Return the total earnings
    }
}
