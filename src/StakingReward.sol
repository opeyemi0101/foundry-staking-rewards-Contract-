// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingReward is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;
    error StakingReward__AmountMustBeMoreThanZero();
    error StakingReward__CannotWithdrawMoreThanStaked();
    error StakingReward__RewardDurationNotFinished();
    error StakingReward__ProvidedRewardTooHigh();

    IERC20 public immutable i_stakingToken;
    IERC20 public immutable i_rewardsToken;

    uint256 public duration;
    uint256 public finishAt;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public totalsupply;

    mapping(address => uint256) public balanceOf; // tracks the amount of staking tokens each user has staked

    mapping(address => uint256) public rewards; // tracks the amount of rewards each user has earned but not yet claimed

    mapping(address => uint256) public rewardsPerTokenPaid; // tracks the reward per token value that each user has already been paid for 

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert StakingReward__AmountMustBeMoreThanZero();
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            rewardsPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address stakingToken, address rewardsToken) Ownable(msg.sender) {
        i_stakingToken = IERC20(stakingToken);
        i_rewardsToken = IERC20(rewardsToken);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalsupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored
            + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalsupply;
    }

    function earned(address account) public view returns (uint256) {
        return ((balanceOf[account] * (rewardPerToken() - rewardsPerTokenPaid[account])) / 1e18)
            + rewards[account];
    }

    function stake(uint256 amount) external moreThanZero(amount) nonReentrant updateReward(msg.sender) {

    
        totalsupply += amount;
        balanceOf[msg.sender] += amount;
        i_stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public moreThanZero(amount) nonReentrant updateReward(msg.sender) {
        if (amount > balanceOf[msg.sender]) {
            revert StakingReward__CannotWithdrawMoreThanStaked();
        }
        balanceOf[msg.sender] -= amount;
        totalsupply -= amount;
        i_stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            i_rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    function setRewardsDuration(uint256 duration_) external onlyOwner {
        if (finishAt >= block.timestamp) {
            revert StakingReward__RewardDurationNotFinished();
        }
        duration = duration_;
        emit RewardsDurationUpdated(duration_);
    }

    function notifyRewardAmount(uint256 amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (amount + remainingRewards) / duration;
        }
        if (rewardRate == 0) {
            revert StakingReward__ProvidedRewardTooHigh();
        }
        if (rewardRate * duration > i_rewardsToken.balanceOf(address(this))) {
            revert StakingReward__ProvidedRewardTooHigh();
        }
        finishAt = block.timestamp + duration;
        lastUpdateTime = block.timestamp;
        emit RewardAdded(amount);
    }


        /** Returns the minimum of two uint256 values */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}