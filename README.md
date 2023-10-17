# Attacc

Create pools on Uniswap V4 and automatically use Spark Protocol to maximize yield for LPs.

## Authors

[Batoul Alkarim](https://twitter.com/batoulalkarim) and [Mehran Hydary](https://twitter.com/mehranhydary).

## Overview

Attacc is a Uniswap V4 hook that allows developers and builders to create liquidity pools that automatically leverage Spark Protocol's sDAI. Hooks can enable liquidity providers to earn yield on their liquidity if the pools are created with ETH or DAI.

### Context

#### Pools paired with ETH

1. Spark has a lending protocol called SparkLend. Any ETH deposited into this hook will be used in SparkLend. When the ETH is deposited into SparkLend, the protocol will borrow sDAI / DAI. The borrowed collateral stays as float in the protocol.
2. <>
3. <>

#### Pools paired with DAI

1. Spark has a yield bearing stablecoin called Spark sDAI (sDAI). Any DAI deposited into this hook will be swapped for sDAI.
2. When this hook is used to swap from the other token into DAI, the hook swaps the pool's sDAI into DAI and sends an amount to the user. The excess DAI (yield generated) will go to the liquidity provider.

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

-   [ ]

### License

This project is licensed under the AGPL-3.0-only

### Disclaimer

This is experimental software and is provided on an "as is" and "as available" basis.
