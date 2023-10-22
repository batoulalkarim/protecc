import Nav from "../components/Nav";
import styles from "../styles/Pools.module.scss";
import React from "react";
const Profile = () => {
  return (
    <div>
      <Nav />
      <div className={styles.container}>
        <div className={styles.title}>Pools</div>
        <div className={styles.subtitle}>view active pools</div>
        <div className={styles.contentContainer}>
          <div className={styles.content}>
            <div className={styles.header}>
              <div> </div>
              <div className={styles.title}>Add liquidity</div>
              <div className={styles.searchIcon}>icon</div>
            </div>
            <div className={styles.tipMessage}>
              <p className={styles.message}>
                <span className={styles.bold}>Tip:</span> When you add
                liquidity, you will receive pool tokens representing your
                position. These tokens automatically earn fees proportional to
                your share of the pool, and can be redeemed at any time.
              </p>
            </div>
            <div className={styles.liquiditycontainer}>
              <div className={styles.daiContainer}>
                <div className={styles.left}>
                  <input className={styles.input} placeholder="0" />
                </div>
                <div className={styles.right}>
                  <div className={styles.daiSelect}>
                    <div className={styles.daiBG}>
                      <img
                        src="/profileAssets/dai.png"
                        alt=""
                        className={styles.dai}
                      />
                      <p>DAI</p>
                    </div>
                  </div>
                  <p>Balance: 0.98300023</p>
                </div>
              </div>
              <div className={styles.plus}>
                <p>+</p>
              </div>
              <div className={styles.otherContainer}>
                <div className={styles.left}>
                  <input className={styles.input} placeholder="0" />
                </div>
                <div className={styles.right}>
                  <div className={styles.selectContainer}>
                    <p>Select a token</p>
                    <img
                      src="/profileAssets/arrowDown.png"
                      alt=""
                      className={styles.downArrow}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className={styles.button}>Invalid Pair</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile;
