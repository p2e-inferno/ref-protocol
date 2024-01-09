import React from "react";
import { ReadOnlyFunctionForm } from "../scaffold-eth/Contract/ReadOnlyFunctionForm";
import { Abi, AbiFunction } from "abitype";
import { useDeployedContractInfo, useDiamondLoupe } from "~~/hooks/scaffold-eth";
import { GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const DiamondLoupe = () => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");

  const diamondLoupe = useDiamondLoupe();

  const functionsToDisplay = (
    ((diamondLoupe.abi || []) as Abi).filter(part => part.type === "function") as AbiFunction[]
  )
    .filter(fn => {
      const isQueryableWithParams = fn.stateMutability === "view" || fn.stateMutability === "pure";
      return isQueryableWithParams;
    })
    .map(fn => {
      return {
        fn,
        inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[fn.name],
      };
    })
    .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));

  if (!functionsToDisplay.length) {
    return <>No read methods</>;
  }

  return (
    <>
      {functionsToDisplay.map(({ fn, inheritedFrom }) => (
        <ReadOnlyFunctionForm
          abi={diamondLoupe.abi as Abi}
          contractAddress={diamondContractData?.address || ""}
          abiFunction={fn}
          key={fn.name}
          inheritedFrom={inheritedFrom}
        />
      ))}
    </>
  );
};
