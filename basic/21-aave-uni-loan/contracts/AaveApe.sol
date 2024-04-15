// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import './AaveUniswapBase.sol';
import './interfaces/IUniswapV3Factory.sol';
import './interfaces/IUniswapV3Pool.sol';
import './libraries/ReserveConfiguration.sol';
import './libraries/TickMath.sol';
import './libraries/WadRayMath.sol';
import './libraries/PercentageMath.sol';
// import 'hardhat/console.sol';

contract AaveApe is AaveUniswapBase {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    event Ape(address ape, string action, address apeAsset, address borrowAsset, uint256 borrowAmount, uint256 apeAmount, uint256 interestRateMode);

    uint24[4] public v3Fees = [100, 500, 3000, 10000];

    IUniswapV3Factory public constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984); // const value for all chains
  
    constructor(
        address lendingPoolAddressesProviderAddress,
        address uniswapRouterAddress
    ) AaveUniswapBase(lendingPoolAddressesProviderAddress, uniswapRouterAddress) {}

    // Gets the amount available to borrow for a given address for a given asset
    function getAvailableBorrowInAsset(address borrowAsset, address ape) public view returns (uint256) {
        // availableBorrowsBase V3 USD based
        (, , uint256 availableBorrowsBase, , , ) = LENDING_POOL().getUserAccountData(ape);
        return getAssetAmount(borrowAsset, availableBorrowsBase);
    }

    // return asset amount with its decimals
    function getAssetAmount(address asset, uint256 amountIn) public view returns (uint256) {
        //All V3 markets use USD based oracles which return values with 8 decimals.
        uint256 assetPrice = getPriceOracle().getAssetPrice(asset); 
        (uint256 decimals, , , , , , , , , ) = getProtocolDataProvider().getReserveConfigurationData(asset);
        uint256 assetAmount = amountIn * 10**decimals / assetPrice;
        return assetAmount;
    }

    // 1. Borrows the maximum amount available of a borrowAsset (in the designated interest rate mode)
    // Note: requires the user to have delegated credit to the Aave Ape Contract
    // 2. Converts it into apeAsset via Uniswap
    // 3. Deposits that apeAsset into Aave on  behalf of the borrower
    function ape(address apeAsset, address borrowAsset, uint256 interestRateMode) public returns (bool) {
        // Get the maximum amount available to borrow in the borrowAsset
        uint256 borrowAmount = getAvailableBorrowInAsset(borrowAsset, msg.sender);

        require(borrowAmount > 0, 'Requires credit on Aave!');

        IPool _lendingPool = LENDING_POOL();

        // Borrow from Aave
        _lendingPool.borrow(borrowAsset, borrowAmount, interestRateMode, 0, msg.sender);

        // Approve the Uniswap Router on the borrowed asset
        IERC20(borrowAsset).approve(UNISWAP_ROUTER_ADDRESS, borrowAmount);

        // Execute trade on Uniswap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: borrowAsset,
            tokenOut: apeAsset,
            fee: getBestPool(borrowAsset, apeAsset).fee(),
            recipient: address(this),
            deadline: block.timestamp + 50,
            amountIn: borrowAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 outputAmount = UNISWAP_ROUTER.exactInputSingle(params);

        IERC20(apeAsset).approve(ADDRESSES_PROVIDER.getPool(), outputAmount);

        _lendingPool.supply(apeAsset, outputAmount, msg.sender, 0);

        emit Ape(msg.sender, 'open', apeAsset, borrowAsset, borrowAmount, outputAmount, interestRateMode);

        return true;
    }

    function superApe(address apeAsset, address borrowAsset, uint256 interestRateMode, uint levers) public returns (bool) {
        // Call "ape" for the number of levers specified
        for (uint i = 0; i < levers; i++) {
            ape(apeAsset, borrowAsset, interestRateMode);
        }

        return true;
    }

    // lever up your position
    function flashApe(address apeAsset, address borrowAsset, uint256 borrowAmount,uint256 interestRateMode) external returns (bool) {
        require(borrowAmount > 0, "borrow amount should be greater than 0");
        require(interestRateMode == 1 || interestRateMode == 2, "interestRateMode must be 1 for stable rate or 2 for variable rate");

        // Get the maximum amount available to borrow in the borrowAsset
        uint256 maxBorrowAmount = getAvailableBorrowInAsset(borrowAsset, msg.sender);
        require(maxBorrowAmount > 0, 'Requires credit on Aave!'); 

        IPool _lendingPool = LENDING_POOL();
        //if borrow amount less than maxBorrowAmount
        if (borrowAmount <= maxBorrowAmount) {
            // Borrow from Aave
            _lendingPool.borrow(borrowAsset, borrowAmount, interestRateMode, 0, msg.sender);
            return true;
        }

        uint256 newHealthFactor = getHealthFactor(apeAsset, borrowAsset, borrowAmount);
        require(newHealthFactor > 1.1e18, "health factor < 1.1, risky!");

        //flashload
        IUniswapV3Pool pool = getBestPool(apeAsset, borrowAsset);

        //DAI/WETH   token0 DAI token1 WETH   zeroForOne false    数量 0.1 余额  336.6DAI WETH 0  delta0 0 delta1 0.1
        //DAI/WETH   zeroForOne true 借出  amount 0.1 数量 DAI   swap 成 0.000297 WETH     DAI 0  dele0 0.1  delta1 0
        bool zeroForOne = pool.token0() == borrowAsset; // borrow apeAsset(token0)

        uint160 sqrtPriceX96 = zeroForOne == true ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
        
        (int256 amount0, int256 amount1) = pool.swap(
            address(this), 
            zeroForOne,
            int256(borrowAmount),
            sqrtPriceX96,
            abi.encode(address(pool), zeroForOne, apeAsset, borrowAsset, interestRateMode, msg.sender)
        );

        emit Ape(msg.sender, 'flashApe', apeAsset, borrowAsset, borrowAmount, zeroForOne == true ? uint256(amount0) : uint256(amount1), interestRateMode);

        //check slippage， minAmountout
        return true;
    }

    function getHealthFactor(address apeAsset, address borrowAsset, uint256 borrowAmount) public view returns (uint256 healthFactor) {

        (uint256 totalCollateralBase,uint256 totalDebtBase, ,uint256 currentLiquidationThreshold, ,) = LENDING_POOL().getUserAccountData(msg.sender);

        uint256 borrowAssetPrice = getPriceOracle().getAssetPrice(borrowAsset); 
        (uint256 decimals, , , , , , , , , ) = getProtocolDataProvider().getReserveConfigurationData(borrowAsset);
        //borrow asset in base currency
        uint256 borrowAssetBase = borrowAmount / 10**decimals * borrowAssetPrice;

        DataTypes.ReserveConfigurationMap memory apeAssetConfiguration = LENDING_POOL().getConfiguration(apeAsset);
        uint256 apeAssetLiquidationThreshold = ReserveConfiguration.getLiquidationThreshold(apeAssetConfiguration);

        healthFactor = (totalCollateralBase.percentMul(currentLiquidationThreshold) + borrowAssetBase.percentMul(apeAssetLiquidationThreshold)).wadDiv(totalDebtBase + borrowAssetBase);
    }

    // Unwind a position (long apeAsset, short borrowAsset)
    function unwindApe(address apeAsset, address borrowAsset, uint256 interestRateMode) public {
        // Get the user's outstanding debt
        (, uint256 stableDebt, uint256 variableDebt, , , , , , ) = getProtocolDataProvider().getUserReserveData(borrowAsset, msg.sender);

        uint256 repayAmount;
        if (interestRateMode == 1) {
            repayAmount = stableDebt;
        } else if (interestRateMode == 2) {
            repayAmount = variableDebt;
        }

        require(repayAmount > 0, 'Requires debt on Aave!');

        // Prepare the flashLoan parameters
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = borrowAsset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = abi.encode(msg.sender, apeAsset, interestRateMode);
        uint16 referralCode = 0;

        LENDING_POOL().flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
    }

    // This is the function that the Lending pool calls when flashLoan has been called and the funds have been flash transferred
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == ADDRESSES_PROVIDER.getPool(), 'only the lending pool can call this function');
        require(initiator == address(this), 'the ape did not initiate this flashloan');

        // Calculate the amount owed back to the lendingPool
        address borrowAsset = assets[0];
        uint256 repayAmount = amounts[0];
        uint256 amountOwing = repayAmount + premiums[0];

        // Decode the parameters
        (address ape, address apeAsset, uint256 rateMode) = abi.decode(params, (address, address, uint256));

        // Close position & repay the flashLoan
        return closePosition(ape, apeAsset, borrowAsset, repayAmount, amountOwing, rateMode);
    }

    function closePosition(
        address ape,
        address apeAsset,
        address borrowAsset,
        uint256 repayAmount,
        uint256 amountOwing,
        uint256 rateMode
    ) internal returns (bool) {

        IPool _lendingPool = LENDING_POOL();

        address _lendingPoolAdress = ADDRESSES_PROVIDER.getPool();
        // Approve the lendingPool to transfer the repay amount
        IERC20(borrowAsset).approve(_lendingPoolAdress, repayAmount);

        // Repay the amount owed
        _lendingPool.repay(borrowAsset, repayAmount, rateMode, ape);

        // Calculate the amount available to withdraw (the smaller of the borrow allowance and the aToken balance)
        uint256 maxCollateralAmount = getAvailableBorrowInAsset(apeAsset, ape);

        DataTypes.ReserveData memory reserve = getAaveAssetReserveData(apeAsset);

        IERC20 _aToken = IERC20(reserve.aTokenAddress);

        if (_aToken.balanceOf(ape) < maxCollateralAmount) {
            maxCollateralAmount = _aToken.balanceOf(ape);
        }

        // transfer the aTokens to this address, then withdraw the Tokens from Aave
        _aToken.transferFrom(ape, address(this), maxCollateralAmount);

        _lendingPool.withdraw(apeAsset, maxCollateralAmount, address(this));

        // Make the swap on Uniswap
        IERC20(apeAsset).approve(UNISWAP_ROUTER_ADDRESS, maxCollateralAmount);

        // Execute trade on Uniswap
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: apeAsset,
            tokenOut: borrowAsset,
            fee: getBestPool(apeAsset, borrowAsset).fee(),
            recipient: address(this),
            deadline: block.timestamp + 5,
            amountOut: amountOwing,
            amountInMaximum: maxCollateralAmount, 
            sqrtPriceLimitX96: 0
        });

        uint256 amountIn =  UNISWAP_ROUTER.exactOutputSingle(params);

        // Deposit any leftover back into Aave on behalf of the user
        uint256 leftoverAmount = maxCollateralAmount - amountIn;

        if (leftoverAmount > 0) {
            IERC20(apeAsset).approve(_lendingPoolAdress, leftoverAmount);

            _lendingPool.supply(apeAsset, leftoverAmount, ape, 0);
        }

        // Approve the Aave Lending Pool to recover the flashloaned amount
        IERC20(borrowAsset).approve(_lendingPoolAdress, amountOwing);

        emit Ape(ape, 'close', apeAsset, borrowAsset, amountOwing, amountIn, rateMode);

        return true;
    }

    // get max liquidity pool
    function getBestPool(address token0, address token1) public view returns(IUniswapV3Pool bestPool) {
        uint128 poolLiquidity = 0;
        uint128 maxLiquidity = 0;

        for (uint256 i = 0; i < v3Fees.length; i++) {
            address pool = factory.getPool(token0, token1, v3Fees[i]);

            if (pool == address(0)) {
                continue;
            }

            poolLiquidity = IUniswapV3Pool(pool).liquidity();

            if (maxLiquidity < poolLiquidity) {
                maxLiquidity = poolLiquidity;
                bestPool = IUniswapV3Pool(pool);
            }
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta, 
        int256 amount1Delta, 
        bytes calldata data
    ) external {
        // console.log("uniswapV3SwapCallback", uint256(amount0Delta), uint256(amount1Delta));
        (
            address _pool,
            bool zeroForOne,
            address apeAsset,
            address borrowAsset,
            uint256 interestRateMode,
            address apeAddress // user address
        ) = abi.decode(data, (address, bool, address, address, uint256, address));

        uint256 repayAmount = uint256(zeroForOne == true ? amount0Delta: amount1Delta);

        if (repayAmount > 0) {
            IPool _lendingPool = LENDING_POOL();

            uint256 swapedApeAssetBalance = IERC20(apeAsset).balanceOf(address(this));
            IERC20(apeAsset).approve(ADDRESSES_PROVIDER.getPool(), swapedApeAssetBalance);

            _lendingPool.supply(apeAsset, swapedApeAssetBalance, apeAddress, 0);

            // Borrow from Aave
            _lendingPool.borrow(borrowAsset, repayAmount, interestRateMode, 0, apeAddress);
            
            IERC20(borrowAsset).transfer(msg.sender, repayAmount);
            // console.log("repay");
        }
    }
}
