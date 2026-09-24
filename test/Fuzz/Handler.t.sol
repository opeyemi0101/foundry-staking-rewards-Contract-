// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakingReward} from "../../src/StakingReward.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    StakingReward public stakingReward;
    ERC20Mock public stakingToken;
    ERC20Mock public rewardsToken;
    address public owner;

    address[] public users;
    uint256 public constant MAX_STAKE_SIZE = 1_000_000e18;
    uint256 public constant MAX_REWARD_SIZE = 1_000_000e18;
    uint256 public timesRewardFunded;

    constructor(
        StakingReward _stakingReward,
        ERC20Mock _stakingToken,
        ERC20Mock _rewardsToken,
        address _owner
    ) {
        stakingReward = _stakingReward;
        stakingToken = _stakingToken;
        rewardsToken = _rewardsToken;
        owner = _owner;
    }

    function stake(uint256 userSeed, uint256 amount) public {
        address user = _pickUser(userSeed);
        amount = bound(amount, 1, MAX_STAKE_SIZE);
        stakingToken.mint(user, amount);

        vm.startPrank(user);
        stakingToken.approve(address(stakingReward), amount);
        stakingReward.stake(amount);
        vm.stopPrank();
    }

    function withdraw(uint256 userSeed, uint256 amount) public {
        address user = _pickUser(userSeed);
        uint256 userBalance = stakingReward.balanceOf(user);
        if (userBalance == 0) {
            return;
        }
        amount = bound(amount, 1, userBalance);

        vm.prank(user);
        stakingReward.withdraw(amount);
    }

    function getReward(uint256 userSeed) public {
        address user = _pickUser(userSeed);
        vm.prank(user);
        stakingReward.getReward();
    }

    function fundReward(uint256 amount, uint256 durationSeed) public {
        amount = bound(amount, 1e18, MAX_REWARD_SIZE);
        uint256 duration_ = bound(durationSeed, 1 days, 30 days);

        rewardsToken.mint(owner, amount);

        vm.startPrank(owner);
        if (stakingReward.finishAt() < block.timestamp) {
            stakingReward.setRewardsDuration(duration_);
        }
        rewardsToken.transfer(address(stakingReward), amount);
        stakingReward.notifyRewardAmount(amount);
        vm.stopPrank();

        timesRewardFunded++;
    }

    function warpTime(uint256 secondsToWarp) public {
        secondsToWarp = bound(secondsToWarp, 1, 10 days);
        vm.warp(block.timestamp + secondsToWarp);
    }

   function _pickUser(uint256 seed) internal returns (address) {
    if (users.length < 10) {
        address newUser = address(uint160(uint256(keccak256(abi.encodePacked(seed, block.timestamp)))));
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == newUser) {
                return newUser; // already tracked, don't push again
            }
        }
        users.push(newUser);
        return newUser;
    } else {
        uint256 index = seed % users.length;
        return users[index];
    }
}

    function getUsers() public view returns (address[] memory) {
        return users;
    }
}
