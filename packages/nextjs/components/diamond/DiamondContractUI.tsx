import { WriteOnlyFunctionForm } from "../scaffold-eth/Contract/WriteOnlyFunctionForm";
import { DiamondCut } from "./DiamondCut";
import { DiamondFacets } from "./DiamondFacets";
import { DiamondLoupe } from "./DiamondLoupe";
import { DiamondOwnership } from "./DiamondOwnership";
import { Abi } from "abitype";
import { Spinner } from "~~/components/assets/Spinner";
import { ReadOnlyFunctionForm } from "~~/components/scaffold-eth";
import { Address, Balance } from "~~/components/scaffold-eth";
import { useDeployedContractInfo, useNetworkColor } from "~~/hooks/scaffold-eth";
import { useFacetFunctionsToDisplay } from "~~/hooks/scaffold-eth/useFacetFunctionsToDisplay";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";

type DiamondContractUIProps = {
  contractName: ContractName;
  className?: string;
};

/**
 * UI component to interface with deployed contracts.
 **/
export const DiamondContractUI = ({ contractName, className = "" }: DiamondContractUIProps) => {
  const { targetNetwork } = useTargetNetwork();
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);
  const networkColor = useNetworkColor();
  const { data: diamondContractData } = useDeployedContractInfo("YourDiamondContract");
  const { writableFunctionsToDisplay } = useFacetFunctionsToDisplay("YourDiamondContract");
  const { readableFunctionsToDisplay } = useFacetFunctionsToDisplay("YourDiamondContract");

  if (deployedContractLoading) {
    return (
      <div className="mt-14">
        <Spinner width="50px" height="50px" />
      </div>
    );
  }

  if (!deployedContractData) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractName}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }

  return (
    <div className={`grid grid-cols-1 lg:grid-cols-6 px-6 lg:px-10 lg:gap-12 w-full max-w-7xl my-0 ${className}`}>
      <div className="col-span-5 grid grid-cols-1 lg:grid-cols-3 gap-8 lg:gap-10">
        <div className="col-span-1 flex flex-col">
          <div className="bg-base-100 border-base-300 border shadow-md shadow-secondary rounded-3xl px-6 lg:px-8 mb-6 space-y-1 py-4">
            <div className="flex">
              <div className="flex flex-col gap-1">
                <span className="font-bold">{contractName}</span>
                <Address address={deployedContractData.address} />
                <div className="flex gap-1 items-center">
                  <span className="font-bold text-sm">Balance:</span>
                  <Balance address={deployedContractData.address} className="px-0 h-1.5 min-h-[0.375rem]" />
                </div>
              </div>
            </div>
            {targetNetwork && (
              <p className="my-0 text-sm">
                <span className="font-bold">Network</span>:{" "}
                <span style={{ color: networkColor }}>{targetNetwork.name}</span>
              </p>
            )}
          </div>
        </div>
        {contractName === "YourDiamondContract" || contractName.includes("DiamondContract") ? (
          <div className="col-span-1 lg:col-span-2 flex flex-col gap-6">
            <div className="col-span-1 lg:col-span-2 flex flex-col gap-6">
              <div className="z-10">
                <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
                  <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                    <div className="flex items-center justify-center space-x-2">
                      <p className="my-0 text-xs">Diamond</p>
                    </div>
                  </div>
                  <div className="p-5 divide-y divide-base-300">
                    {writableFunctionsToDisplay.map(({ fn, inheritedFrom }, idx) => (
                      <WriteOnlyFunctionForm
                        abi={diamondContractData?.abi as Abi}
                        key={`${fn.name}-${idx}}`}
                        abiFunction={fn}
                        onChange={() => console.log("ONCHANGE!!!")}
                        contractAddress={diamondContractData?.address || ""}
                        inheritedFrom={inheritedFrom}
                      />
                    ))}
                    {readableFunctionsToDisplay.map(({ fn, inheritedFrom }) => (
                      <ReadOnlyFunctionForm
                        abi={diamondContractData?.abi as Abi}
                        contractAddress={diamondContractData?.address || ""}
                        abiFunction={fn}
                        key={fn.name}
                        inheritedFrom={inheritedFrom}
                      />
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <div className="z-10">
              <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
                <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                  <div className="flex items-center justify-center space-x-2">
                    <p className="my-0 text-xs">Loupe Facet</p>
                  </div>
                </div>
                <div className="p-5 divide-y divide-base-300">
                  <DiamondLoupe />
                </div>
              </div>
            </div>
            <div className="z-10">
              <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
                <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                  <div className="flex items-center justify-center space-x-2">
                    <p className="my-0 text-sm">Cut Facet</p>
                  </div>
                </div>
                <div className="p-5 divide-y divide-base-300">
                  <DiamondCut onChange={() => console.log("ONCHANGE!!!")} />
                </div>
              </div>
            </div>
            <div className="z-10">
              <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
                <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                  <div className="flex items-center justify-center space-x-2">
                    <p className="my-0 text-sm">Ownership</p>
                  </div>
                </div>
                <div className="p-5 divide-y divide-base-300">
                  <DiamondOwnership onChange={() => console.log("DIAMOND OWNER")} />
                </div>
              </div>
            </div>
          </div>
        ) : contractName.includes("Facet") ? (
          <DiamondFacets contractName={contractName} />
        ) : (
          <p>
            {`No contract Diamond Contract or Facet found by the name of "${contractName}" on chain "${targetNetwork.name}"!`}
          </p>
        )}
      </div>
    </div>
  );
};