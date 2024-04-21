import { useEffect } from "react";
// import abis from "@unlock-protocol/contracts";
import { PublicLockV13 } from "@unlock-protocol/contracts";
// import networks from "@unlock-protocol/networks";
// import { Paywall } from "@unlock-protocol/paywall";
import { ethers } from "ethers";
import type { NextPage } from "next";
import { useLocalStorage } from "usehooks-ts";
import { useAccount } from "wagmi";
// import { useContractWrite } from "wagmi";
import { MetaHeader } from "~~/components/MetaHeader";
import { DiamondContractUI } from "~~/components/diamond/DiamondContractUI";
import { affiliateAbi } from "~~/utils/affiliate_abi";
import { campaignAbi } from "~~/utils/campaign_abi";
import { useEthersSigner } from "~~/utils/ethers";
// import { useEthersProvider } from "~~/utils/ethers-provider";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getContractNames } from "~~/utils/scaffold-eth/contractNames";


const selectedContractStorageKey = "scaffoldEth2.selectedContract";
const contractNames = getContractNames();

const DebugDiamond: NextPage = () => {
  const [selectedContract, setSelectedContract] = useLocalStorage<ContractName>(
    selectedContractStorageKey,
    contractNames[0],
  );
  const { address } = useAccount();

  const signer = useEthersSigner();
  const unadusAddress = "0x5B49842B3c5e84E0E3B63109e10D513404B20452";

  const checkout = async () => {
    const publicLockContract = new ethers.Contract(
      "0x49d9d5da131dcf47900590a4beebbc939fb89f4a",
      PublicLockV13.abi,
      signer,
    );
    const amount = await publicLockContract.keyPrice();
    const purchaseParams = [
      [amount],
      [address],
      [unadusAddress],
      [ethers.constants.AddressZero],
      // [ethers.utils.defaultAbiCoder.encode(["address"], ["0xE11Cd5244DE68D90755a1d142Ab446A4D17cDC10"])],
      [ethers.utils.defaultAbiCoder.encode(["address"], ["0x8fa4bfbb396a76ebf79379c59f597867cf880ac4"])],
      // [ethers.utils.defaultAbiCoder.encode(["address"], [ethers.constants.AddressZero])],
    ];
    const options = {
      value: amount,
      gasLimit: 3000000,
    };
    const tx = await publicLockContract.purchase(...purchaseParams, options);
    // const tx = await publicLockContract.purchase(...purchaseParams);
    console.log("ccvc::", tx);
  };

  const becomeAffiliate = async () => {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, affiliateAbi, signer);
      const tx = await campaignContract.becomeAffiliate(
        "0x0000000000000000000000000000000000000000",
        "0xe3be68055bbE3C1f1df30BA40ad6727900De8948",
      );
      console.log("txX::becomeAffiliate", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  };

  const setName = async () => {
    try {
      const campaignContract = new ethers.Contract("0x503bB6b04e23019E6de37EB3f0989A1bEB0826A1", campaignAbi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setName("FERNO VIBES: Genesis");
      console.log("txX::setName", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  };

  async function setTiersCommission() {
    try {
      const campaignContract = new ethers.Contract("0xea4F659F633B6836244098752BEec05d2fF2167E", campaignAbi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setTiersCommission(
        "0xf1f85abef77169e1602a6ca7f45ab71aa1b0ae4b",
        2000,
        5000,
        3000,
      );
      console.log("txX::setName", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  }

  // const getAffiliatesOf = async () => {
  //   try {
  //     const campaignContract = new ethers.Contract("0xea4F659F633B6836244098752BEec05d2fF2167E", abi, signer);
  //     // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
  //     const tx = await campaignContract.getCampaignId();
  //     console.log("txX::setNameTX", tx);
  //     console.log("txX::setNameTXData", tx.data);
  //     return tx;
  //   } catch (e) {
  //     console.log("AFFILIATE_ERR::", e);
  //   }
  // };

  useEffect(() => {
    if (!contractNames.includes(selectedContract)) {
      setSelectedContract(contractNames[0]);
    }
  }, [selectedContract, setSelectedContract]);

  return (
    <>
      <MetaHeader
        title="Debug Diamond Contracts | Scaffold-ETH 2"
        description="Debug your deployed 🏗 Scaffold-ETH 2 diamond contracts in an easy way"
      />
      <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
        {contractNames.length === 0 ? (
          <p className="text-3xl mt-14">No contracts found!</p>
        ) : (
          <>
            {contractNames.length > 1 && (
              <div className="flex flex-row gap-2 w-full max-w-7xl pb-1 px-6 lg:px-10 flex-wrap">
                {contractNames.map(contractName => (
                  <button
                    className={`btn btn-secondary btn-sm font-thin ${
                      contractName === selectedContract ? "bg-base-300" : "bg-base-100"
                    }`}
                    key={contractName}
                    onClick={() => setSelectedContract(contractName)}
                  >
                    {contractName}
                  </button>
                ))}
              </div>
            )}
            {contractNames.map(contractName => (
              <>
                <DiamondContractUI
                  key={contractName}
                  contractName={contractName}
                  className={contractName === selectedContract ? "" : "hidden"}
                />
              </>
            ))}
          </>
        )}
      </div>
      <div className="text-center mt-8 bg-secondary p-10">
        <div>
          <button onClick={becomeAffiliate} className="btn btn-sm">
            Become Affiliate
          </button>
          <button onClick={setName} className="ml-2 btn btn-accent btn-sm">
            Set Name
          </button>
          {/* <button onClick={getAffiliatesOf} className="ml-2 btn btn-accent btn-sm">
            Get AffiliatesOf
          </button> */}
          <button onClick={setTiersCommission} className="ml-2 btn btn-accent btn-sm">
            Set Tiers
          </button>
          <button onClick={checkout} className="ml-2 btn btn-accent btn-sm">
            Checkout
          </button>
        </div>
        <h1 className="text-4xl my-0">Debug Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            packages / nextjs / pages / debug-diamond.tsx
          </code>{" "}
        </p>
      </div>
    </>
  );
};

export default DebugDiamond;