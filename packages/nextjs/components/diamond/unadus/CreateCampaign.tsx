import { useState } from "react";
import { CopyIcon } from "./assets/CopyIcon";
import { DiamondIcon } from "./assets/DiamondIcon";
import { HareIcon } from "./assets/HareIcon";
import { ArrowSmallRightIcon } from "@heroicons/react/24/outline";
import { Spinner } from "~~/components/Spinner";
import { Address } from "~~/components/scaffold-eth";
import { useDeployedContractInfo, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

export const CreateCampaign: React.FC = () => {
  const [name, setName] = useState("");
  const [lock, setLock] = useState("");
  const [l1Commission, setL1Commission] = useState<bigint>(BigInt(0));
  const [l2Commission, setL2Commission] = useState<bigint>(BigInt(0));

  {
    /* const [l2Commission, setL2Commission] = <bigint>(BigInt(0));
  const [l3Commission, setL3Commission] = <bigint>(BigInt(0));
  const [withdrawalDelay, setWithdrawalDelay] = <bigint>(BigInt(0)); */
  }

  {
    /* const { writeAsync, isLoading } = useScaffoldContractWrite({
    contractNAME: "YourDiamondContract",
    functionName: "createCampaign",
    args: [name, lock, l1Commission, l2Commission, l3Commission, withdrawalDelay],
    onBlockConfirmation: txnReceipt => {
      console.log("📦 Transaction blockHash", txnReceipt.blockHash);
    },
  }); */
  }

  {
    /* const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo("YourDiamondContract");
  if (deployedContractLoading) {
    return (
      <div className="mt-6 pt-6 flex items-center justify-center">
        <Spinner width="50px" height="50px" />
      </div>
    );
  } */
  }

  return (
    <div className="flex bg-base-300 relative pb-10">
      <DiamondIcon className="absolute top-24" />
      <CopyIcon className="absolute bottom-0 left-36" />
      <HareIcon className="absolute right-0 bottom-24" />
      {/* <div className="flex flex-col w-full mx-5 sm:mx-8 2xl:mx-20">
        <div className="flex flex-col mt-6 px-7 py-8 bg-base-200 opacity-80 rounded-2xl shadow-lg border-2 border-primary">
          <h1 className="flex items-center justify-center">
            <strong className="mr-4">Hook Address:</strong> <Address address={deployedContractData?.address} />
          </h1>
          <div className="text-center">
            <div>
              <span className="text-4xl sm:text-5xl text-black">Set Discount For Lock</span>
            </div>
          </div>

          <div className="mt-8 flex flex-col items-start gap-2 sm:gap-5">
            <div className="w-full">
              <input
                type="text"
                placeholder="Enter lock address"
                className="input font-bai-jamjuree w-full px-5 bg-[url('/assets/gradient-bg.png')] bg-[length:100%_100%] border border-primary text-lg sm:text-2xl placeholder-black"
                onChange={e => setLock(e.target.value)}
              />
            </div>
            <div className="w-full">
              <input
                type="text"
                placeholder="Enter signer address"
                className="input font-bai-jamjuree w-full px-5 bg-[url('/assets/gradient-bg.png')] bg-[length:100%_100%] border border-primary text-lg sm:text-2xl placeholder-black"
                // onChange={e => setSigner(e.target.value)}
              />
            </div>
            <div className="w-full">
              <input
                type="number"
                placeholder="Enter discount"
                className="input font-bai-jamjuree w-full px-5 bg-[url('/assets/gradient-bg.png')] bg-[length:100%_100%] border border-primary text-lg sm:text-2xl placeholder-black"
                onChange={e => {
                  const val = BigInt(e.target.value);
                  setDiscount(val);
                }}
              />
            </div>
          </div>

          <div className="mt-6 w-full">
            <button
              className={`btn btn-primary rounded-full w-full capitalize font-normal font-white flex items-center gap-1 hover:gap-2 transition-all tracking-widest ${
                isLoading ? "loading" : ""
              }`}
              onClick={() => writeAsync()}
            >
              {!isLoading && (
                <>
                  Send <ArrowSmallRightIcon className="w-3 h-3 mt-0.5" />
                </>
              )}
            </button>
          </div>
        </div>
      </div> */}
    </div>
  );
};
