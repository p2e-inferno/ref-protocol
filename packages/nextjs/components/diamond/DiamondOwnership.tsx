import React, { useEffect, useState } from "react";
import { ReadOnlyFunctionForm } from "../scaffold-eth";
import { WriteOnlyFunctionForm } from "../scaffold-eth/Contract/WriteOnlyFunctionForm";
import { Abi, AbiFunction } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useDiamondOwnership } from "~~/hooks/scaffold-eth/useDiamondOwnership";
import { GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const DiamondOwnership = ({ onChange }: { onChange: () => void }) => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const [writeFunctionsToDisplay, setWriteFunctionsToDisplay] = useState<any>();
  const [readFunctionsToDisplay, setReadFunctionsToDisplay] = useState<any>();

  const diamondOwnership = useDiamondOwnership();

  useEffect(() => {
    if (!diamondOwnership) return;
    const _writeFunctionsToDisplay = (
      (diamondOwnership.abi as Abi).filter(part => part.type === "function") as AbiFunction[]
    )
      .filter(fn => {
        const isWriteableFunction = fn.stateMutability !== "view" && fn.stateMutability !== "pure";
        return isWriteableFunction;
      })
      .map(fn => {
        return {
          fn,
          inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[
            fn.name
          ],
        };
      })
      .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
    setWriteFunctionsToDisplay(_writeFunctionsToDisplay);
  }, [diamondContractData, diamondOwnership]);

  useEffect(() => {
    if (!diamondOwnership) return;
    const _readFunctionsToDisplay = (
      (diamondOwnership.abi as Abi).filter(part => part.type === "function") as AbiFunction[]
    )
      .filter(fn => {
        const isWriteableFunction = fn.stateMutability === "view" || fn.stateMutability === "pure";
        return isWriteableFunction;
      })
      .map(fn => {
        return {
          fn,
          inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[
            fn.name
          ],
        };
      })
      .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
    setReadFunctionsToDisplay(_readFunctionsToDisplay);
  }, [diamondContractData, diamondOwnership]);

  if (writeFunctionsToDisplay && !writeFunctionsToDisplay.length) {
    return <>No write methods</>;
  }

  return (
    <>
      {readFunctionsToDisplay &&
        readFunctionsToDisplay.map(({ fn, inheritedFrom }: any) => (
          <ReadOnlyFunctionForm
            abi={diamondOwnership.abi as Abi}
            contractAddress={diamondContractData?.address || ""}
            abiFunction={fn}
            key={fn.name}
            inheritedFrom={inheritedFrom}
          />
        ))}
      {writeFunctionsToDisplay &&
        writeFunctionsToDisplay.map(({ fn, inheritedFrom }: any, idx: number) => (
          <WriteOnlyFunctionForm
            abi={diamondOwnership.abi as Abi}
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
