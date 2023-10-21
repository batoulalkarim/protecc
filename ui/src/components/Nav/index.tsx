import styles from "../../styles/Nav.module.scss";
import { useAccount, useDisconnect } from "wagmi";
import { useRouter } from "next/router";

export default function Nav() {
  const router = useRouter();
  const { address } = useAccount();
  const { disconnect } = useDisconnect();
  return (
    <div className={styles.container}>
      {address ? (
        <>
          <div className={styles.flex}>
            <div className={styles.protect} onClick={() => router.push("/")}>
              Protecc Yourself
            </div>
            <div className={styles.links}>
              <p onClick={() => router.push("/profile")}>Portfolio</p>
              <p onClick={() => router.push("/pools")}>Pools</p>
            </div>
          </div>
          <button
            className={styles.disconnectButton}
            onClick={() => disconnect()}
          >
            Disconnect
          </button>
        </>
      ) : (
        <>
          <div className={styles.protect}>Protecc Yourself</div>
          <div className={styles.attack}>Attacc Others</div>
        </>
      )}
    </div>
  );
}
