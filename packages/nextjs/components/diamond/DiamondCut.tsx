import React from "react";
import { WriteOnlyFunctionForm } from "../scaffold-eth/Contract/WriteOnlyFunctionForm";
import { Abi, AbiFunction } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useDiamondCut } from "~~/hooks/scaffold-eth/useDiamondCut";
import { GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const DiamondCut = ({ onChange }: { onChange: () => void }) => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  // const [refreshDisplayVariables, triggerRefreshDisplayVariables] = useReducer(value => !value, false);
  const diamondCut = useDiamondCut();

  const functionsToDisplay = ((diamondCut.abi as Abi).filter(part => part.type === "function") as AbiFunction[])
    .filter(fn => {
      const isWriteableFunction = fn.stateMutability !== "view" && fn.stateMutability !== "pure";
      return isWriteableFunction;
    })
    .map(fn => {
      return {
        fn,
        inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[fn.name],
      };
    })
    .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));

  if (!functionsToDisplay.length) {
    return <>No write methods</>;
  }

  return (
    <>
      {functionsToDisplay.map(({ fn, inheritedFrom }, idx) => (
        <WriteOnlyFunctionForm
          abi={diamondCut.abi as Abi}
          key={`${fn.name}-${idx}}`}
          abiFunction={fn}
          onChange={onChange}
          contractAddress={diamondContractData?.address || ""}
          inheritedFrom={inheritedFrom}
        />
      ))}
    </>
  );
};
