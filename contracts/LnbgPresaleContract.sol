// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error waitForSale();
error roundSupplyLimitExceed();
error pleaseSendTokenPrice();
error invalidUSDTPrice();
error minimumAndMaximumLimit();

contract LngbPreSaleContract is Ownable {
    bool public isSale;

    uint256 public salePrice;
    uint256 public raisedAmount;

    IERC20 USDTToken;
    IERC20 USDCToken;
    IERC20 PreSaleToken;

    event buyHistory(address _addr, uint256 _amount, string _paymentType);

    constructor(
        address _usdt, //0x55d398326f99059ff775485246999027b3197955 USDT BNB
        address _usdc, //0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d USDC BNB
        address _saleToken
    ) {
        USDTToken = IERC20(_usdt);
        USDCToken = IERC20(_usdc);
        PreSaleToken = IERC20(_saleToken);
        salePrice = 0.1 ether;
    }

    function startTheSale() public onlyOwner {
        require(!isSale, "already Started");
        isSale = true;
    }

    function changeSalePrice(uint256 _priceInUSDT) external onlyOwner {
        require(_priceInUSDT > 0, "Price must be greater than Zero");
        salePrice = _priceInUSDT;
    }


    function buyWithBNB(uint256 _amount) external payable returns (bool) {
        if (!isSale) {
            revert waitForSale();
        }

        if (PreSaleToken.balanceOf(address(this)) < _amount) {
            revert roundSupplyLimitExceed();
        }

        uint256 payAmountInUSD = sellTokenInUDSTPrice(_amount);
        if (payAmountInUSD < 1 ether || payAmountInUSD > 3000 ether) {
            revert minimumAndMaximumLimit();
        }

        uint256 payAmount = sellTokenInETHPrice(_amount);
        if (msg.value < payAmount) {
            revert pleaseSendTokenPrice();
        }

        payable(owner()).transfer(msg.value);
        PreSaleToken.transfer(msg.sender, _amount);
        raisedAmount += payAmountInUSD;
        emit buyHistory(msg.sender, _amount, "BNB");
        return true;
    }

    function buyWithUSDT(uint256 _buyToken, bool isUsdt)
        external
        returns (bool)
    {
        if (!isSale) {
            revert waitForSale();
        }

        uint256 payAmountInUSD = sellTokenInUDSTPrice(_buyToken);

        if (payAmountInUSD < 1 ether || payAmountInUSD > 3000 ether) {
            revert minimumAndMaximumLimit();
        }

        if (isUsdt) {
            if (PreSaleToken.balanceOf(address(this)) < _buyToken) {
                revert roundSupplyLimitExceed();
            }

            uint256 payAmount = USDTToken.allowance(msg.sender, address(this));
            if (payAmountInUSD < payAmount) {
                revert pleaseSendTokenPrice();
            }

            USDTToken.transferFrom(msg.sender, owner(), payAmountInUSD);
            PreSaleToken.transfer(msg.sender, _buyToken);

            raisedAmount += payAmountInUSD;
            emit buyHistory(msg.sender, _buyToken, "USDT");
            return true;
        } else {
            if (PreSaleToken.balanceOf(address(this)) < _buyToken) {
                revert roundSupplyLimitExceed();
            }

            uint256 payAmount = USDCToken.allowance(msg.sender, address(this));
            if (payAmountInUSD < payAmount) {
                revert pleaseSendTokenPrice();
            }

            USDCToken.transferFrom(msg.sender, owner(), payAmountInUSD);
            PreSaleToken.transfer(msg.sender, _buyToken);
            raisedAmount += payAmountInUSD;
            emit buyHistory(msg.sender, _buyToken, "USDC");
            return true;
        }
    }

    function getLatestUSDTPrice() public view returns (uint256) {
        //0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46 USDt/ETH Ethereum mainnet
        //0xD5c40f5144848Bd4EF08a9605d860e727b991513 USDt/BNB BNBSmart mainnet
        AggregatorV3Interface USDTPriceFeed = AggregatorV3Interface(
            0xD5c40f5144848Bd4EF08a9605d860e727b991513
        ); // Mainnet contract address for USDT price feed
        (, int256 price, , , ) = USDTPriceFeed.latestRoundData(); // Get the latest USDT price data from Chainlink

        if (price <= 0) {
            // Ensure that the price is valid
            revert invalidUSDTPrice();
        }
        return uint256(price);
    }

    
    function sellTokenInETHPrice(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 tokensAmountPriceInUSDT = sellTokenInUDSTPrice(_amount);
        uint256 amountInEth = calculateAmountInEther(tokensAmountPriceInUSDT);
        return amountInEth;
    }

    function calculateAmountInEther(uint256 _tokensAmountPrice)
        internal
        view
        returns (uint256)
    {
        uint256 amountinEthers = (_tokensAmountPrice) / 10**18;
        uint256 amountInEth = getLatestUSDTPrice() * amountinEthers;
        return amountInEth;
    }


    function sellTokenInUDSTPrice(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 tokensAmountPrice = ((salePrice * _amount) / 10**18);
        return tokensAmountPrice;
    }

    function withdrawTokens(uint256 _amount) external onlyOwner returns (bool) {
        PreSaleToken.transfer(owner(), _amount);
        return true;
    }
}
