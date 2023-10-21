# Attacc

Create pools on Uniswap V4 and automatically use Spark Protocol to maximize yield for LPs.

## Authors

[Batoul Alkarim](https://twitter.com/batoulalkarim) and [Mehran Hydary](https://twitter.com/mehranhydary).

## Overview

Attacc is a Uniswap V4 hook that allows developers and builders to create liquidity pools that automatically leverage Spark Protocol's sDAI and SparkLend. Hooks can enable liquidity providers to earn yield on their liquidity if the pools are created with ETH or DAI.

### Context

#### Pools paired with DAI

1. Spark has a yield bearing stablecoin called Savings sDAI (sDAI). Any DAI deposited into this hook can earn yield as sDAI.
2. As users make swaps, the tick of the pool changes. That means that a different portion of the DAI (and other token) deposited is active for traders to use to swap. When this is true, we need to keep some DAI available for traders. The rest can earn yield as sDAI.
3. We use hooks in Uniswap V4 to update the sDAI and DAI balances of this contract based on tick changes and liquidity. The hooks implemented are `afterInitiaze`, `afterSwap`, and `beforeModifyPosition` and `afterModifyPosition`.

### Benefits

1. Users can earn additional yield on their liquidity (instead of only having their liquidity earn yield when users are making trades).
2. The hook can hold ERC-1155 and ERC-4626 tokens and that reduces the cost of using the benefits of using Uniswap V4 and Spark Protocol.

### Mechanism

1. Hooks used:
2. ERC20 base is Solady
3. Deployment is outlined in `script/`

### Usage

To use this hook:

1. <>
2. <>

### Deployment

```

```

### Bonus

### Todo

-   [ ] Handle ETH pools (Spark has a lending protocol called SparkLend. Any ETH deposited into this hook will be used in SparkLend. When the ETH is deposited into SparkLend, the protocol will borrow sDAI / DAI. The borrowed collateral stays as float in the protocol.)

### License

This project is licensed under the AGPL-3.0-only

### Disclaimer

This is experimental software and is provided on an "as is" and "as available" basis.
