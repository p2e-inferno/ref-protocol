// import { useEffect, useState } from "react";
// import { Abi, AbiFunction } from "abitype";
// import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
// import { ContractName, GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";
// /**
//  * Retrieves the diamondOwner facet instance.
//  */
// export const useFacetsFunctionsToDisplay = <TContractName extends ContractName>(contractName: TContractName) => {
//   const { data: diamondContractData } = useDeployedContractInfo("Diamond");
//   const { data: diamondFacetData } = useDeployedContractInfo(contractName);
//   const [writeFunctionsToDisplay, setWriteFunctionsToDisplay] = useState<any[]>([]);
//   const [readFunctionsToDisplay, setReadFunctionsToDisplay] = useState<any[]>([]);
//   useEffect(() => {
//     if (!diamondFacetData) return;
//     const _writeFunctionsToDisplay = (
//       (diamondFacetData.abi as Abi).filter(part => part.type === "function") as AbiFunction[]
//     )
//       .filter(fn => {
//         const isWriteableFunction = fn.stateMutability !== "view" && fn.stateMutability !== "pure";
//         return isWriteableFunction;
//       })
//       .map(fn => {
//         return {
//           fn,
//           inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[
//             fn.name
//           ],
//         };
//       })
//       .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
//     setWriteFunctionsToDisplay(_writeFunctionsToDisplay);
//   }, [diamondContractData, diamondFacetData]);
//   useEffect(() => {
//     if (!diamondFacetData) return;
//     const _readFunctionsToDisplay = (
//       (diamondFacetData.abi as Abi).filter(part => part.type === "function") as AbiFunction[]
//     )
//       .filter(fn => {
//         const isWriteableFunction = fn.stateMutability === "view" || fn.stateMutability === "pure";
//         return isWriteableFunction;
//       })
//       .map(fn => {
//         return {
//           fn,
//           inheritedFrom: ((diamondContractData as GenericContract)?.inheritedFunctions as InheritedFunctions)?.[
//             fn.name
//           ],
//         };
//       })
//       .sort((a, b) => (b.inheritedFrom ? b.inheritedFrom.localeCompare(a.inheritedFrom) : 1));
//     setReadFunctionsToDisplay(_readFunctionsToDisplay);
//   }, [diamondContractData, diamondFacetData]);
//   return { readFunctionsToDisplay, writeFunctionsToDisplay };
// };
import { useEffect, useState } from "react";
import { Abi, AbiFunction } from "abitype";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { ContractName, GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const useFacetsFunctionsToDisplay = <TContractName extends ContractName>(contractName: TContractName) => {
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
