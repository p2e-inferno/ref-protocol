import { useEffect } from "react";
import { ethers } from "ethers";
import type { NextPage } from "next";
import { useLocalStorage } from "usehooks-ts";
// import { useContractWrite } from "wagmi";
import { MetaHeader } from "~~/components/MetaHeader";
import { DiamondContractUI } from "~~/components/diamond/DiamondContractUI";
import { abi } from "~~/utils/campaign_abi";
import { useEthersSigner } from "~~/utils/ethers";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getContractNames } from "~~/utils/scaffold-eth/contractNames";


const selectedContractStorageKey = "scaffoldEth2.selectedContract";
const contractNames = getContractNames();

const DebugDiamond: NextPage = () => {
  const [selectedContract, setSelectedContract] = useLocalStorage<ContractName>(
    selectedContractStorageKey,
    contractNames[0],
  );
  // const { data, isLoading, isSuccess, write } = useContractWrite({
  //   address: "0xCE5a6d75EB5c36D747d8dc96396f6c1a9e57fc1C",
  //   abi,
  //   functionName: "becomeAffiliate",
  //   args: ["0xca7632327567796e51920f6b16373e92c7823854"],
  // });
  const signer = useEthersSigner();
  // try {
  //   const contract = new ethers.Contract("0xCE5a6d75EB5c36D747d8dc96396f6c1a9e57fc1C", abi, provider);
  //   console.log("gs", contract);
  // } catch (e) {
  //   console.log(e);
  // }

  const becomeAffiliate = async () => {
    try {
      const campaignContract = new ethers.Contract("0xCE5a6d75EB5c36D747d8dc96396f6c1a9e57fc1C", abi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setName("FERNO VIBES: Genesis");
      console.log("txX::", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  };

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