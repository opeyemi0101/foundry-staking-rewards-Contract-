// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StakingReward} from "../src/StakingReward.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract DeployStakingReward is Script{

    function run() external returns (StakingReward, ERC20Mock, ERC20Mock) {
        vm.startBroadcast();

        ERC20Mock stakingToken = new ERC20Mock();
        ERC20Mock rewardsToken = new ERC20Mock();

        StakingReward stakingReward = new StakingReward(address(stakingToken), address(rewardsToken));

        vm.stopBroadcast();

        return (stakingReward, stakingToken, rewardsToken);
    }
    
}