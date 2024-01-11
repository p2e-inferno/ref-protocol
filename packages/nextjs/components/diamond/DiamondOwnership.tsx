import React from "react";
import { ReadOnlyFunctionForm } from "../scaffold-eth";
import { WriteOnlyFunctionForm } from "../scaffold-eth/Contract/WriteOnlyFunctionForm";
import { Abi } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useDiamondOwnership } from "~~/hooks/scaffold-eth/useDiamondOwnership";
import { useFacetsFunctionsToDisplay } from "~~/hooks/scaffold-eth/useFacetsFunctionsToDisplay";

export const DiamondOwnership = ({ onChange }: { onChange: () => void }) => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { writableFunctionsToDisplay, readableFunctionsToDisplay } = useFacetsFunctionsToDisplay("OwnershipFacet");
  const diamondOwnership = useDiamondOwnership();

  if (writableFunctionsToDisplay && !writableFunctionsToDisplay.length) {
    return <>No write methods</>;
  }

  return (
    <>
      {readableFunctionsToDisplay &&
        readableFunctionsToDisplay.map(({ fn, inheritedFrom }: any) => (
          <ReadOnlyFunctionForm
            abi={diamondOwnership.abi as Abi}
            contractAddress={diamondContractData?.address || ""}
            abiFunction={fn}
            key={fn.name}
            inheritedFrom={inheritedFrom}
          />
        ))}
      {writableFunctionsToDisplay &&
        writableFunctionsToDisplay.map(({ fn, inheritedFrom }: any, idx: number) => (
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
