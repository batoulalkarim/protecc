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

  return (
    <div>
      <Nav />
      <div className={styles.container}>
        <div>Profile Page</div>
        <div className={styles.content}>
          <div className={styles.ethAssets}>
            <p>Ethereum Network</p>
            <div className={styles.ethTable}>
              <div className={styles.row}>liquidity positions here</div>
              <div className={styles.row}>liquidity positions here</div>
              <div className={styles.row}>liquidity positions here</div>
              <div className={styles.row}>liquidity positions here</div>
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
