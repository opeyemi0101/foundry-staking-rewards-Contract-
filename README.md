# Staking Rewards

A Foundry project implementing a staking rewards contract: users stake one ERC20 token and earn another, with rewards distributed linearly over a funded period. The reward accounting follows the Synthetix `StakingRewards` pattern.

## How it works

- **Stake / withdraw**: users deposit the staking token and can withdraw any amount of their balance at any time.
- **Rewards**: the owner funds the contract with reward tokens and sets a duration. Rewards stream out at a constant rate per second, split between stakers in proportion to their share of the pool.
- **Claim**: `getReward()` pays out earned rewards. `exit()` withdraws the full stake and claims rewards in one call.
- **Top-ups**: funding mid-period rolls the unspent rewards into a new rate over a fresh duration, so nothing already promised is lost.

Accounting uses a `rewardPerToken` accumulator. Each user's rewards are settled lazily (inside the `updateReward` modifier) whenever they stake, withdraw, or claim, so no loops over stakers are needed.

## Contract

| Function | Access | Description |
|---|---|---|
| `stake(amount)` | anyone | Deposit staking tokens |
| `withdraw(amount)` | anyone | Withdraw staked tokens |
| `getReward()` | anyone | Claim earned rewards |
| `exit()` | anyone | Withdraw everything and claim |
| `earned(account)` | view | Rewards earned by an account |
| `rewardPerToken()` | view | Accumulated reward per staked token (1e18 scale) |
| `setRewardsDuration(duration)` | owner | Set reward period length (only after the current period ends) |
| `notifyRewardAmount(amount)` | owner | Start or extend a reward period (the contract must already hold the tokens) |

Built with OpenZeppelin `Ownable` and `ReentrancyGuard`. Custom errors are used instead of revert strings.

## Getting started

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Install

```bash
git clone https://github.com/opeyemi0101/foundry-staking-rewards-Contract-.git
cd foundry-staking-rewards-Contract-
forge install
```

### Build and test

```bash
forge build
forge test
forge test --gas-report
```

### Deploy

Local (Anvil):

```bash
anvil
forge script script/DeployStakingReward.s.sol --rpc-url http://127.0.0.1:8545 --private-key <anvil_private_key> --broadcast
```

Sepolia:

```bash
forge script script/DeployStakingReward.s.sol --rpc-url $SEPOLIA_RPC_URL --account <your-keystore-account> --broadcast
```

The script deploys two mock ERC20 tokens and the `StakingReward` contract wired to them.

## Testing

- **Unit tests** (`test/unit/StakingRewardTest.t.sol`): staking and withdrawing, zero-amount and missing-approval reverts, owner-only functions, the duration guard, claiming with no stake, and the full exit flow.
- **Invariant tests** (`test/Fuzz/`): a `Handler` drives bounded random sequences of stake, withdraw, claim, funding, and time jumps. Foundry then checks after every call that:
  1. the contract's reward token balance always covers all earned rewards
  2. `totalsupply` always equals the sum of individual staked balances
  3. the contract's staking token balance always covers `totalsupply`

  Fuzzing is restricted to the Handler's functions with `targetSelector`, so every action is realistic and tracked.

Run the invariant suite on its own:

```bash
forge test --match-contract StakingRewardInvariantTest -vvv
```

## Static analysis

Slither was run against `src/StakingReward.sol`. The findings on the contract itself were expected patterns (timestamp-based reward math, divide-then-multiply in the solvency check, `i_` immutable naming). The rest were in OpenZeppelin library code.

## Project structure

```
src/
  StakingReward.sol
script/
  DeployStakingReward.s.sol
test/
  unit/
    StakingRewardTest.t.sol
  Fuzz/
    Handler.t.sol
    StakingRewardInvariantTest.t.sol
```

## Deployments

| Network | Contract | Address |
|---|---|---|
| Sepolia | StakingReward | `0x...` |

Addresses are recorded in `broadcast/DeployStakingReward.s.sol/11155111/run-latest.json`.

## Disclaimer

This is an educational project built while working through the Cyfrin Solidity curriculum. It has not been audited. Do not use it with real funds.

## License

MIT
