import React from "react";
import { WriteOnlyFunctionForm } from "../scaffold-eth/Contract/WriteOnlyFunctionForm";
import { Abi } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useDiamondCut } from "~~/hooks/scaffold-eth/useDiamondCut";
import { useFacetsFunctionsToDisplay } from "~~/hooks/scaffold-eth/useFacetsFunctionsToDisplay";

export const DiamondCut = ({ onChange }: { onChange: () => void }) => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { writableFunctionsToDisplay } = useFacetsFunctionsToDisplay("DiamondCutFacet");
  // const [refreshDisplayVariables, triggerRefreshDisplayVariables] = useReducer(value => !value, false);
  const diamondCut = useDiamondCut();

  if (!writableFunctionsToDisplay.length) {
    return <>No write methods</>;
  }

  return (
    <>
      {writableFunctionsToDisplay.map(({ fn, inheritedFrom }, idx) => (
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
