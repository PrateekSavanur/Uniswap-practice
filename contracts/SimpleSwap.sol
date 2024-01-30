// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/IERC20.sol";

contract SwapExamples {
    // swap router for Mainnet, Goerli, Arbitrum, Optimism, Polygon
    address public constant s_swapRouter =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(s_swapRouter);

    address public immutable STAKE;
    address public immutable REWARD;

    IERC20 public stake;
    IERC20 public reward;

    uint24 public constant poolFee = 3000;

    constructor(address _token1, address _token2) {
        STAKE = _token1;
        REWARD = _token2;
        stake = IERC20(_token1);
        reward = IERC20(_token2);
    }

    function swapExactInputSingle(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        reward.transferFrom(msg.sender, address(this), amountIn);

        reward.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: STAKE,
                tokenOut: REWARD,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        reward.transferFrom(msg.sender, address(this), amountInMaximum);

        reward.approve(address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: STAKE,
                tokenOut: REWARD,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            reward.approve(address(swapRouter), 0);
            reward.transfer(msg.sender, amountInMaximum - amountIn);
        }
    }
}
