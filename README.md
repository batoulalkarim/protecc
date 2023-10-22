# Protecc

Create pools on Uniswap V4 and automatically use Spark Protocol to maximize yield for LPs.

## Authors

[Batoul Alkarim](https://twitter.com/batoulalkarim) and [Mehran Hydary](https://twitter.com/mehranhydary).

## Overview

Protecc is a Uniswap V4 hook that allows developers and builders to create liquidity pools that automatically leverage Spark Protocol's sDAI and SparkLend. Hooks can enable liquidity providers to earn yield on their liquidity if the pools are created with ETH or DAI.

### Context

#### Pools paired with DAI

1. Spark has a yield bearing stablecoin called Savings sDAI (sDAI). Any DAI deposited into this hook can earn yield as sDAI.
2. As users make swaps, the range of active liquidity can change. That means that a different portion of the DAI deposited is active for traders to use to swap. Since this is true, we need to keep some DAI available for traders. The rest can earn yield as sDAI.
3. We use hooks in Uniswap V4 to update the sDAI and DAI balances of this contract based on tick changes and liquidity. The hooks implemented are `afterInitialize`, `afterSwap`, and `beforeModifyPosition` and `afterModifyPosition`.

#### NFTs as identifiers

1. We are using Axelar and a simple NFT contract to capture liquidity positions in our Uniswap V4 hook. To save on gas costs, we deployed the NFT on Scroll network. Whenever a user adds / removes liquidity, we create a simple NFT for them on the Scroll network with Axelar messaging.

### Benefits

1. Users can earn additional yield on their liquidity (instead of only having their liquidity earn yield when users are making trades).
2. The hook can hold ERC-1155 and ERC-4626 tokens and that reduces the cost of using the benefits of using Uniswap V4 and Spark Protocol.

### Mechanism

1. Hooks used:
2. ERC20 base is Solady
3. Deployment is outlined in `script/`

### Usage

To use this hook:

1. Deploy `NewIdea` hook on mainnet
2. Create a pool with the hook with ETH and DAI
3. Once the pool is ready, add liquidity (in ETH and DAI) at various ranges
4. Deploy the `NFT` on the Scroll network

### Deployment

```

```

### Bonus

### Todo

-   [ ] Handle ETH pools (Spark has a lending protocol called SparkLend. Any ETH deposited into this hook will be used in SparkLend. When the ETH is deposited into SparkLend, the protocol will borrow sDAI / DAI. The borrowed collateral stays as float in the protocol.)
-   [ ] Handle rewards better (right now we wrap and unwrap DAI to Savings DAI but we are not keeping track of rewards properly). In the future, we want to make it clear to the liquidity provider how much they are earning from swap fees and how much they are earning from Savings DAI when their DAI is not in position.

### License

This project is licensed under the AGPL-3.0-only

### Disclaimer

This is experimental software and is provided on an "as is" and "as available" basis.
