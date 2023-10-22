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
2. The Scroll NFT is deployed [here](https://scrollscan.com/address/0xf149159900732baa70deae97940f02a75ff39fab).

### Benefits

1. Users can earn additional yield on their liquidity (instead of only having their liquidity earn yield when users are making trades).
2. The hook can hold ERC-1155 and ERC-4626 tokens and that reduces the cost of using the benefits of using Uniswap V4 and Spark Protocol.

### Mechanism

1. Before Modify Position Hook - when a user wants to remove liquidity, there might not be enough DAI in the hook since some of the DAI is stored as sDAI. We call `_ensureAmountsForModifyPosition` to unwind some sDAI for the user (if necessary) and then the user can exit the pool with ease for the range specified.
2. After Modify Position Hook - since liquidity is being added or removed, the ticks will change. When ticks of the hook change, that means the active liquidity changes too. We call `_handleLiquidityPositions` to review the balances of DAI and sDAI to ensure that the active liquidity range has the correct amount of DAI so people can trade.
3. After Swap Hook - once the trade occurs, the ticks will change again. We call `_handleLiquidityPositions` once more to ensure that that only the DAI required for the active tick range will be available for trade and the rest will be earning yield as sDAI.
4. We have our own `modifyPosition` function because we want to use NFTs on Scroll network to capture the `ModifyPositionParams` for users. This will be used to calculate how much sDAI yield can be allocated for a user. We use Axelar to send a message to their mainnet contract and this message tells Axelar to relay a message to an NFT contract (that we deployed) on Scroll network and mint an NFT with the relevant `ModifyPositionParams` details.

### Deployment

```
# Make sure you have funds on ETH and Scroll

# For the NFT
forge script script/ProteccNft.s.sol \
 --rpc-url $SCROLL_URL \
 --private-key $PK \
 --broadcast

# Get the address of the deployed ProteccNft contracto on scroll
# and then update the file script/Protecc.s.sol with the value
# for the variable referring to destinationAddress

# For the Hook
forge script script/Protecc.s.sol \
 --rpc-url $ETH_URL \
 --private-key $PK \
 --broadcast

# Need to add details re. the run inputs (token address, pool manager (once deployed on mainnet), and destination address (whcih is the token above on scroll network))
```

### Bonus

### Todo

-   [ ] Handle ETH pools (Spark has a lending protocol called SparkLend. Any ETH deposited into this hook will be used in SparkLend. When the ETH is deposited into SparkLend, the protocol will borrow sDAI / DAI. The borrowed collateral stays as float in the protocol.)
-   [ ] Handle rewards better (right now we wrap and unwrap DAI to Savings DAI but we are not keeping track of rewards properly). In the future, we want to make it clear to the liquidity provider how much they are earning from swap fees and how much they are earning from Savings DAI when their DAI is not in position.
-   [ ] Update the NFT metadata so that it incorporates more data related to the modify position call (e.g. ticks, liquidity, dates, etc.) - we can use this to distribute awards later

### License

This project is licensed under the AGPL-3.0-only

### Disclaimer

This is experimental software and is provided on an "as is" and "as available" basis.
