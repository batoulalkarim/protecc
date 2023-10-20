import React from "react";
import { useAccount, useConnect, useDisconnect } from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
import styles from "../../styles/WalletConnect.module.scss";

const WalletConnect = ({ handleNext }: { handleNext: () => void }) => {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect({
    connector: new InjectedConnector(),
  });
  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Protecc</h1>
      {isConnected ? (
        <div className={styles.connectedContainer}>
          <div className={styles.connectedText}>Connected to {address}</div>
          <button
            className={styles.disconnectButton}
            onClick={() => handleNext()}
          >
            Trade
          </button>
        </div>
      ) : (
        <button className={styles.connectButton} onClick={() => connect()}>
          <span>Connect Wallet</span>
        </button>
      )}
    </div>
  );
};

export default WalletConnect;
