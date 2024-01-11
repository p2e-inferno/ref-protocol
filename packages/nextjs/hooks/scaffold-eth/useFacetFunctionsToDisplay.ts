import { useEffect, useState } from "react";
import { Abi, AbiFunction } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractName, GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const useFacetFunctionsToDisplay = <TContractName extends ContractName>(contractName: TContractName) => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { data: diamondFacetData } = useDeployedContractInfo(contractName);

  const [writableFunctionsToDisplay, setWritableFunctionsToDisplay] = useState<any[]>([]);
  const [readableFunctionsToDisplay, setReadableFunctionsToDisplay] = useState<any[]>([]);

  const getFunctionsToDisplay = (isWriteable: boolean) => {
    if (!diamondFacetData) return [];

    return ((diamondFacetData.abi as Abi).filter(part => part.type === "function") as AbiFunction[])
      .filter(fn =>
        isWriteable
          ? fn.stateMutability !== "view" && fn.stateMutability !== "pure"
          : fn.stateMutability === "view" || fn.stateMutability === "pure",
      )
      .map(fn => ({
        fn,
        inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[fn.name],
      }))
      .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
  };
  useEffect(() => {
    setWritableFunctionsToDisplay(getFunctionsToDisplay(true));
    setReadableFunctionsToDisplay(getFunctionsToDisplay(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [diamondContractData, diamondFacetData]);

  return { readableFunctionsToDisplay, writableFunctionsToDisplay };
};
