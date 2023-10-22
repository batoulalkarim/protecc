import React from "react";
import Nav from "../components/Nav";
import styles from "../styles/Profile.module.scss";
import Image from "next/image";
const Profile = () => {
  //turn into objects witth more data
  let images = [
    "/profileAssets/1.png",
    "/profileAssets/2.png",
    "/profileAssets/3.png",
    "/profileAssets/4.png",
    "/profileAssets/5.png",
    "/profileAssets/6.png",
    "/profileAssets/7.png",
    "/profileAssets/8.png",
    "/profileAssets/9.png",
    "/profileAssets/10.png",
  ];

  //need eth fake data
  let ethData = [
    {
      coinLogo: "/profileAssets/mog.png",
      coinName: "Mog Coin",
      chainLogo: "/profileAssets/mog.png",
      chainName: "Ethereum",
      balanceUSD: "$21,978.85",
      balanceInCoin: "1.0000000e+12 MOG",
      priceUSD: "$0.00",
      pricePercent: "+23.73",
      up: true,
    },
    {
      coinLogo: "/profileAssets/ethcircle.png",
      coinName: "Ethereum",
      chainLogo: "/profileAssets/ethcircle.png",
      chainName: "Ethereum",
      balanceUSD: "$1,548.25",
      balanceInCoin: "0.99751 ETH",
      priceUSD: "$1,552.11",
      pricePercent: "-1.79",
      up: false,
    },
    {
      coinLogo: "/profileAssets/optimism.png",
      coinName: "Optimism",
      chainLogo: "/profileAssets/optimism.png",
      chainName: "Optimism",
      balanceUSD: "$934.79",
      balanceInCoin: "794.187 OP",
      priceUSD: "$1.18",
      pricePercent: "-2.16",
      up: false,
    },
    {
      coinLogo: "/profileAssets/icetoken.png",
      coinName: "IceToken",
      chainLogo: "/profileAssets/binance.png",
      chainName: "BSC",
      balanceUSD: "$79.93",
      balanceInCoin: "73.00 ICE",
      priceUSD: "$1.09",
      pricePercent: "+16.84",
      up: true,
    },
  ];
  return (
    <div>
      <Nav />
      <div className={styles.container}>
        <div className={styles.title}>Portfolio</div>
        <div className={styles.content}>
          <div className={styles.ethAssets}>
            <p>Ethereum Network</p>

            <div className={styles.ethTable}>
              <div className={styles.labels}>
                <div className={styles.NameLabel}>NAME</div>
                <div> </div>
                <div className={styles.balanceAndPrice}>
                  <div>BALANCE</div>
                  <div className={styles.priceText}>PRICE</div>
                </div>
              </div>

              {ethData.map((row) => (
                <div className={styles.row} key={row.coinName}>
                  <div className={styles.leftContainer}>
                    <div className={styles.imageContainer}>
                      <div className={styles.images}>
                        <img
                          src="/profileAssets/dai.png"
                          alt=""
                          className={styles.daiImg}
                        />
                        <img
                          src={row.chainLogo}
                          alt=""
                          className={styles.img1}
                        />
                      </div>
                    </div>
                    <div className={styles.coinDetails}>
                      <div className={styles.name}>{row.coinName}</div>
                      <div className={styles.chain}>
                        <img
                          src={row.chainLogo}
                          alt="chain logo"
                          className={styles.chainLogo}
                        />
                        <p className={styles.chainName}>{row.chainName}</p>
                      </div>
                    </div>
                  </div>
                  {/* balance and price details here  */}
                  <div className={styles.balanceAndPriceDetails}>
                    <div className={styles.balanceInfo}>
                      <p>{row.balanceUSD}</p>
                      <p className={styles.balanceInCoin}>
                        {row.balanceInCoin}
                      </p>
                    </div>
                  </div>

                  <div className={styles.priceInfo}>
                    <p>{row.priceUSD}</p>
                    {row.up ? (
                      <p className={styles.green}>{row.pricePercent}%</p>
                    ) : (
                      <p className={styles.red}>{row.pricePercent}%</p>
                    )}
                  </div>
                </div>
              ))}
              {/* table row end  */}
            </div>
          </div>
          <div className={styles.daiAssets}>
            <p>Scroll Network</p>
            <div className={styles.imagesContainer}>
              {images.map((image, index) => (
                <div key={index} className={styles.image}>
                  <Image src={image} alt="" height={240} width={190} />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile;
