// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StakingReward} from "../../src/StakingReward.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract StakingRewardTest is Test {
    StakingReward public stakingReward;
    ERC20Mock public stakingToken;
    ERC20Mock public rewardsToken;

    address public Owner = makeAddr("Owner");
    address public User1 = makeAddr("User 1");
    address public User2 = makeAddr("User 2");

    uint256 public constant STARTING_BALANCE = 10000 ether;
    uint256 public constant STAKING_AMOUNT = 100 ether;
    uint256 public constant REWARD_AMOUNT = 10 ether;
    uint256 public constant REWARD_DURATION = 7 days;

    function setUp() public {
        vm.startPrank(Owner);
        stakingToken = new ERC20Mock();
        rewardsToken = new ERC20Mock();

        stakingReward = new StakingReward(address(stakingToken), address(rewardsToken));
        vm.stopPrank();

        stakingToken.mint(User1, STARTING_BALANCE);
        stakingToken.mint(User2, STARTING_BALANCE);
        rewardsToken.mint(Owner, REWARD_AMOUNT * 10);
    }

    function _fundReward(uint256 rewardAmount) public {
        vm.startPrank(Owner);
        stakingReward.setRewardsDuration(REWARD_DURATION);
        rewardsToken.transfer(address(stakingReward), rewardAmount);
        stakingReward.notifyRewardAmount(rewardAmount);
        vm.stopPrank();
    }

    function testCanStake() public {
        vm.startPrank(User1);
        stakingToken.approve(address(stakingReward), STAKING_AMOUNT);
        stakingReward.stake(STAKING_AMOUNT);
        vm.stopPrank();

        uint256 userBalance = stakingReward.balanceOf(User1);
        assertEq(userBalance, STAKING_AMOUNT, "User balance should be equal to staked amount");
    }

    function testCannotStakeZeroAmount() public {
        vm.startPrank(User1);
        stakingToken.approve(address(stakingReward), 100 ether);
        vm.expectRevert(StakingReward.StakingReward__AmountMustBeMoreThanZero.selector);
        stakingReward.stake(0);
        vm.stopPrank();
    }

    function testStakeRevertsWithoutApproval() public {
        vm.startPrank(User1);
        vm.expectRevert();
        stakingReward.stake(STAKING_AMOUNT);
        vm.stopPrank();
    }

    function testMultipleUsersCanStake() public {
        vm.startPrank(User1);
        stakingToken.approve(address(stakingReward), STAKING_AMOUNT);
        stakingReward.stake(STAKING_AMOUNT);
        vm.stopPrank();

        vm.startPrank(User2);
        stakingToken.approve(address(stakingReward), STAKING_AMOUNT * 2);
        stakingReward.stake(STAKING_AMOUNT * 2);
        vm.stopPrank();

        assertEq(stakingReward.totalsupply(), STAKING_AMOUNT * 3);
        assertEq(stakingReward.balanceOf(User1), STAKING_AMOUNT);
        assertEq(stakingReward.balanceOf(User2), STAKING_AMOUNT * 2);
    }

    function testExitWithdrawAndClaimReward() public {
        _fundReward(REWARD_AMOUNT);
        vm.startPrank(User1);
        stakingToken.approve(address(stakingReward), STAKING_AMOUNT);
        stakingReward.stake(STAKING_AMOUNT);
        vm.warp(block.timestamp + 1 days);
        stakingReward.exit();
        vm.stopPrank();
    }

     function testCannotWithdrawMoreThanStaked() public {

        vm.startPrank(User1);
        stakingToken.approve(address(stakingReward), STAKING_AMOUNT);
        stakingReward.stake(STAKING_AMOUNT);
        vm.expectRevert(StakingReward.StakingReward__CannotWithdrawMoreThanStaked.selector);
        stakingReward.withdraw(STAKING_AMOUNT + 1 ether);
        vm.stopPrank();
        }
        

        function testGetRewardWithoutStaking() public {

            _fundReward(REWARD_AMOUNT);
            // vm.warp(timestamp) is a Foundry cheatcode that fast-forwards the blockchain's 
            // clock during a test — it sets block.timestamp directly to whatever value you pass in.
            vm.warp(block.timestamp + 1 days);
            vm.startPrank(User1);
            stakingReward.getReward();
            assertEq(rewardsToken.balanceOf(User1), 0, "User1 should not receive any rewards without staking");
            vm.stopPrank();

        }

        function testOnlyOwnerCanSetRewardsDuration() public {
             vm.prank(User1);
            vm.expectRevert();
            stakingReward.setRewardsDuration(REWARD_DURATION);
        }

        function testOnlyOwnerCanNotifyRewardAmount() public {
            vm.prank(User1);
            vm.expectRevert();
            stakingReward.notifyRewardAmount(REWARD_AMOUNT);
        }

 function testCannotSetDurationWhileActive() public {

       _fundReward(REWARD_AMOUNT);

        vm.prank(Owner);
         vm.expectRevert(StakingReward.StakingReward__RewardDurationNotFinished.selector);
        
         // meaning a reward period is now actively running.
         stakingReward.setRewardsDuration(REWARD_DURATION);
         
         }

    function testNotifyRewardAmountRevertsIfTooHighForBalance()  public {
        _fundReward(REWARD_AMOUNT); 
        
        }
    }
