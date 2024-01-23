import { Abi } from "abitype";
import { Spinner } from "~~/components/assets/Spinner";
import { ReadOnlyFunctionForm } from "~~/components/scaffold-eth";
import { WriteOnlyFunctionForm } from "~~/components/scaffold-eth";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useFacetFunctionsToDisplay } from "~~/hooks/scaffold-eth/useFacetFunctionsToDisplay";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";

type DiamondContractUIProps = {
  contractName: ContractName;
};

/**
 * UI component to interface with deployed contracts.
 **/
export const DiamondFacets = ({ contractName }: DiamondContractUIProps) => {
  const { targetNetwork } = useTargetNetwork();
  const { data: deployedFacetData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);
  const { data: diamondContractData } = useDeployedContractInfo("YourDiamondContract");

  const { readableFunctionsToDisplay, writableFunctionsToDisplay } = useFacetFunctionsToDisplay(contractName);

  if (deployedContractLoading) {
    return (
      <div className="mt-14">
        <Spinner width="50px" height="50px" />
      </div>
    );
  }

  if (!deployedFacetData) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractName}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }
  const onChange = () => console.log("TESTING FACET WRITE METHOD");

  return (
    <div className="col-span-1 lg:col-span-2 flex flex-col gap-6">
      {readableFunctionsToDisplay.length > 0 && (
        <div className="z-10">
          <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
            <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
              <div className="flex items-center justify-center space-x-2">
                <p className="my-0 text-xs">Read</p>
              </div>
            </div>
            <div className="p-5 divide-y divide-base-300">
              {readableFunctionsToDisplay.map(({ fn, inheritedFrom }) => (
                <ReadOnlyFunctionForm
                  abi={deployedFacetData.abi as Abi}
                  contractAddress={diamondContractData?.address || ""}
                  abiFunction={fn}
                  key={fn.name}
                  inheritedFrom={inheritedFrom}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {writableFunctionsToDisplay.length > 0 && (
        <div className="z-10">
          <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
            <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
              <div className="flex items-center justify-center space-x-2">
                <p className="my-0 text-sm">Write</p>
              </div>
            </div>
            <div className="p-5 divide-y divide-base-300">
              {writableFunctionsToDisplay.map(({ fn, inheritedFrom }, idx) => (
                <WriteOnlyFunctionForm
                  abi={deployedFacetData.abi as Abi}
                  key={`${fn.name}-${idx}`}
                  abiFunction={fn}
                  onChange={onChange}
                  contractAddress={diamondContractData?.address || ""}
                  inheritedFrom={inheritedFrom}
                />
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
