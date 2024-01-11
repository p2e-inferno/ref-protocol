import React from "react";
import { ReadOnlyFunctionForm } from "../scaffold-eth/Contract/ReadOnlyFunctionForm";
import { Abi } from "abitype";
import { useDeployedContractInfo, useDiamondLoupe } from "~~/hooks/scaffold-eth";
import { useFacetFunctionsToDisplay } from "~~/hooks/scaffold-eth/useFacetFunctionsToDisplay";

export const DiamondLoupe = () => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { readableFunctionsToDisplay } = useFacetFunctionsToDisplay("DiamondLoupeFacet");

  const diamondLoupe = useDiamondLoupe();

  if (!readableFunctionsToDisplay.length) {
    return <>No read methods</>;
  }

  return (
    <>
      {readableFunctionsToDisplay.map(({ fn, inheritedFrom }) => (
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
