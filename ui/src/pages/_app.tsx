import "@/styles/globals.css";
import type { AppProps } from "next/app";
import Head from "next/head";
// import Nav from "../components/Nav";
import Image from "next/image";
import { Inter } from "next/font/google";
import { LoginSteps } from "../components/LoginSteps";
import {
  WagmiConfig,
  createConfig,
  configureChains,
  mainnet,
  useConnect,
} from "wagmi";
import { polygonZkEvmTestnet, scrollSepolia } from "wagmi/chains";
import { publicProvider } from "wagmi/providers/public";
import { CoinbaseWalletConnector } from "wagmi/connectors/coinbaseWallet";
import { InjectedConnector } from "wagmi/connectors/injected";
import { MetaMaskConnector } from "wagmi/connectors/metaMask";
import { WalletConnectConnector } from "wagmi/connectors/walletConnect";
const { chains, publicClient, webSocketPublicClient } = configureChains(
  [polygonZkEvmTestnet, scrollSepolia, mainnet],
  [publicProvider()]
);

const config = createConfig({
  autoConnect: true,
  connectors: [new MetaMaskConnector({ chains })],
  publicClient,
  webSocketPublicClient,
});

export default function App({ Component, pageProps }: AppProps) {
  // Check if the current chain is either Scroll Sepolia or Polygon zkEVM testnet
  const isValidChain = chains.find(
    (chain) =>
      chain.network === "polygon-zkevm-testnet" ||
      chain.network === "scroll-sepolia"
  );

  if (!isValidChain) {
    // Redirect or show an error message indicating the user is on an invalid chain
    return (
      <div>
        You are on an invalid chain. Please switch to Scroll Sepolia or Polygon
        zkEVM testnet.
      </div>
    );
  }
  return (
    <WagmiConfig config={config}>
      <Component {...pageProps} />
    </WagmiConfig>
  );
}
