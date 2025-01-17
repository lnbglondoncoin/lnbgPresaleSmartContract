// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function mint(address to, uint amount) external;

    function burn(address owner, uint amount) external;
}

error waitForSale();
error roundSupplyLimitExceed();
error pleaseSendTokenPrice();
error invalidUSDTPrice();
error minimumAndMaximumLimit();

contract WrappedBridgeLnbg is Ownable {
    address public admin;
    IToken public token;
    uint256 public nonce;

    uint256 public salePrice;
    uint256 public raisedAmount;

    IERC20 USDTToken;
    IERC20 USDCToken;

    uint256 conversionRate = 10 ** 12;

    mapping(uint256 => mapping(uint256 => bool)) public processedNonces;

    event WrappedBurn(
        address from,
        address to,
        uint amount,
        uint date,
        uint nonce,
        uint chainId
    );

    event WrappedMint(
        address from,
        address to,
        uint amount,
        uint date,
        uint nonce,
        uint chainId
    );

    event buyHistory(address _addr, uint256 _amount, string _paymentType);

    constructor(address _usdt, address _usdc, address _token) {
        admin = msg.sender;
        token = IToken(_token);
        USDTToken = IERC20(_usdt); //0xdAC17F958D2ee523a2206206994597C13D831ec7 Ethereum
        USDCToken = IERC20(_usdc); //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 Ethereum
        salePrice = 0.03 * 10 ** 6;
    }

    function changeSalePrice(uint256 _priceInUSDT) external onlyOwner {
        require(_priceInUSDT > 0, "Price must be greater than Zero");
        salePrice = _priceInUSDT;
    }

    function burn(
        address _from,
        address _to,
        uint _amount,
        uint _chainId
    ) external {
        token.burn(_from, _amount);
        emit WrappedBurn(_from, _to, _amount, block.timestamp, nonce, _chainId);
        nonce++;
    }

    function mint(
        address _to,
        uint _amount,
        uint _nonce,
        uint _chainId
    ) external {
        require(msg.sender == admin, "only admin");
        require(
            processedNonces[_chainId][_nonce] == false,
            "transfer already processed"
        );

        processedNonces[_chainId][_nonce] = true;
        token.mint(_to, _amount);
        emit WrappedMint(
            msg.sender,
            _to,
            _amount,
            block.timestamp,
            _nonce,
            _chainId
        );
    }

    function updateToken(address _newToken) external onlyOwner {
        token = IToken(_newToken);
    }

    //minting functiion in payable
    function buyWithETH(
        address _to,
        uint256 _amount
    ) external payable returns (bool) {
        uint256 payAmountInUSD = sellTokenInUDSTPrice(_amount, salePrice);

        if (
            payAmountInUSD < (1 * 10 ** 6) || payAmountInUSD > (3000 * 10 ** 6)
        ) {
            revert minimumAndMaximumLimit();
        }

        uint256 payAmount = sellTokenInETHPrice(_amount, salePrice);
        if (msg.value < payAmount) {
            revert pleaseSendTokenPrice();
        }

        payable(owner()).transfer(msg.value);
        token.mint(_to, _amount);
        raisedAmount += payAmountInUSD;
        emit buyHistory(msg.sender, _amount, "ETH");
        return true;
    }

    function buyWithUSDT(
        address _to,
        uint256 _buyToken,
        bool isUsdt
    ) external returns (bool) {
        uint256 payAmountInUSD = sellTokenInUDSTPrice(_buyToken, salePrice);

        if (payAmountInUSD < 1 * 10 ** 6 || payAmountInUSD > 3000 * 10 ** 6) {
            revert minimumAndMaximumLimit();
        }

        if (isUsdt) {
            uint256 payAmount = USDTToken.allowance(msg.sender, address(this));
            if (payAmountInUSD < payAmount) {
                revert pleaseSendTokenPrice();
            }

            USDTToken.transferFrom(msg.sender, owner(), payAmountInUSD);
            token.mint(_to, _buyToken);
            raisedAmount += payAmountInUSD;
            emit buyHistory(msg.sender, _buyToken, "USDT");
            return true;
        } else {
            uint256 payAmount = USDCToken.allowance(msg.sender, address(this));
            if (payAmountInUSD < payAmount) {
                revert pleaseSendTokenPrice();
            }

            USDCToken.transferFrom(msg.sender, owner(), payAmountInUSD);
            token.mint(_to, _buyToken);
            raisedAmount += payAmountInUSD;
            emit buyHistory(msg.sender, _buyToken, "USDC");
            return true;
        }
    }

    function getLatestUSDTPrice() public view returns (uint256) {
        //0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46 USDt/ETH Ethereum mainnet
        //0xD5c40f5144848Bd4EF08a9605d860e727b991513 USDt/BNB BNBSmart mainnet
        AggregatorV3Interface USDTPriceFeed = AggregatorV3Interface(
            0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46
        ); // Mainnet contract address for USDT price feed
        (, int256 price, , , ) = USDTPriceFeed.latestRoundData();

        if (price <= 0) {
            // Ensure that the price is valid
            revert invalidUSDTPrice();
        }
        return uint256(price);
    }

    //this function sell token in Ether 18 decimal
    function sellTokenInETHPrice(
        uint256 _amount,
        uint256 _roundPrice
    ) public view returns (uint256) {
        uint256 conversion = _roundPrice * conversionRate;
        uint256 tokensAmountPrice = ((conversion * _amount) / 10 ** 18) /
            10 ** 12;
        uint256 amountinEthers = tokensAmountPrice * conversionRate;
        uint256 amountInEth = (getLatestUSDTPrice() * amountinEthers) /
            10 ** 18;
        return amountInEth;
    }

    //this function sell token in USDT 6 decimal
    function sellTokenInUDSTPrice(
        uint256 _amount,
        uint256 _roundPrice
    ) public view returns (uint256) {
        uint256 conversion = _roundPrice * conversionRate;
        uint256 tokensAmountPrice = ((conversion * _amount) / 10 ** 18) /
            10 ** 12;
        return tokensAmountPrice;
    }
}
