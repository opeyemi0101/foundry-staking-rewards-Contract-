// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StakingReward} from "../../src/StakingReward.sol"; 
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";



contract StakingRewardInvariantTest is StdInvariant, Test {
    StakingReward public stakingReward;
    ERC20Mock public stakingToken;
    ERC20Mock public rewardsToken;
    Handler public handler;

// foundry cheatcode 
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

    handler = new Handler(stakingReward, stakingToken, rewardsToken, Owner);

    bytes4[] memory selectors = new bytes4[](5);
    selectors[0] = Handler.stake.selector;
    selectors[1] = Handler.withdraw.selector;
    selectors[2] = Handler.getReward.selector;
    selectors[3] = Handler.fundReward.selector;
    selectors[4] = Handler.warpTime.selector;

    targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
}

      /// @notice The contract must always hold enough reward tokens to cover
    /// everything currently earned (claimed + unclaimed) by every staker.
     function invariant_rewardsBalanceCoversEarnedRewards() public view {
        address[] memory users = handler.getUsers();
        uint256 totalEarnedRewards = 0;
        for (uint256 i = 0; i < users.length; i++) {
            totalEarnedRewards += stakingReward.earned(users[i]);   
           
     }
      uint256 contractRewardBalance = rewardsToken.balanceOf(address(stakingReward));

      console.log("Total earned across all users:", totalEarnedRewards);
        console.log("Contract reward tokrn balance:", contractRewardBalance);
            assert(contractRewardBalance >= totalEarnedRewards);
   
}

function invariant_totalSupplyMatchesSumOfBalances() public view {
      address[] memory users = handler.getUsers();
        uint256 sumOfUserBalances;

        for (uint256 i =0; i < users.length; i++){
            sumOfUserBalances += stakingReward.balanceOf(users[i]);
        }
        assertEq(stakingReward.totalsupply(), sumOfUserBalances);
    }


     function invariant_stakingTokenBalanceCoversTotalSupply() public view {
        
        uint256 stakingTokenBalance = stakingToken.balanceOf(address(stakingReward));
        uint256 totalSupply = stakingReward.totalsupply();
        assert(stakingTokenBalance >= totalSupply);
     }

     
    }