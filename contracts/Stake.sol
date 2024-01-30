// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20.sol";

error Staking__TranferFailed();
error Staking__NeedMoreThanZero();

contract Staking {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardsToken;

    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_rewards;
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    uint256 public constant REWARD_RATE = 100;

    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardsToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        //  How much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 earn = (currentBalance * (currentRewardPerToken - amountPaid)) /
            1e18 +
            pastRewards;

        return earn;
    }

    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }

        return
            s_rewardPerTokenStored +
            ((block.timestamp - s_lastUpdateTime * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    function stake(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;
        // emit event

        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        // can do require but this is more gas efficient bcz it returns string
        if (!success) {
            revert Staking__TranferFailed();
        }
    }

    function withdraw(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] -= amount;
        s_totalSupply -= amount;

        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Staking__TranferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardsToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TranferFailed();
        }
    }
}

// Readme

//Do we allow any tokens? - only one ERC20
//or just specific tokens

// Stake : Lock Tokens in smart contract ✅
// keep track of how much user has staked
// keep track of total tokens
// transfet thte tokens to this contracts
// withdraw : unlock and pull out of the contract ✅
// claimReward: users get their reward tokens
// How much do they get ?
// The contract is goint to emit X tokens per second
// And disperse them to all token stakers

// Total 100 reward tokens/ second
// Staked : 50 Staked tokens, 20 Staked tokens, 30 Staked tokens
// rewards: 50 reward token, 20 reward token, 30 reward token

// staked : 100, 50 , 30, 20 (total = 200)
// reward : 50 , 25, 15 , 10
// What's a good reward mechanism
// Whats good reward math

// Update reward
// How much reward per token
// Last timestamp
// between timestamps, earned X tokens

// Approve will happen in FE instead of in contract bcz our contract does not own any tokens
// in staking, user have the tokens, so we need approval from them
// Solidity v0.8 automatically checks for overflow/underflow
// External because its cheaper and no fxn in our contract is goint o use the funciton inside the contract

//
