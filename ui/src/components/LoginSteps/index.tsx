import { useState } from "react";
import { useRouter } from "next/router";
import WalletConnect from "./WalletConnect";
import Trade from "./Trade";

type LoginSteps = "LOGIN" | "TRADE";

export function LoginSteps() {
  const router = useRouter();
  const [step, setStep] = useState<LoginSteps>("LOGIN");

  const handleStep = (step: LoginSteps) => {
    setStep(step);
  };
  return (
    <div>
      {step === "LOGIN" && (
        <WalletConnect handleNext={() => handleStep("TRADE")} />
      )}
      {step === "TRADE" && <Trade handleSkip={() => router.push("/profile")} />}
    </div>
  );
}
