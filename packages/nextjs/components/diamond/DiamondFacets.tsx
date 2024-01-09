import React, { useState } from "react";
// import { useWalletClient } from "wagmi";
import { usePublicClient } from "wagmi";
// import {  } from "wagmi";
import { getContract } from "wagmi/actions";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
// import { useScaffoldContract } from "~~/hooks/scaffold-eth";
// import "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

type Facet = {
  address: string;
  functionSelectors: string[];
};
// interface Props {
//   diamondAddress: string;
// }
// export const DiamondFacets: React.FC<Props> = ({ diamondAddress }) => {
export const DiamondFacets = () => {
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { data: diamondLoupeData } = useDeployedContractInfo("DiamondLoupeFacet");
  const { data: diamondCutData } = useDeployedContractInfo("DiamondCutFacet");

  // const { data: walletClient } = useWalletClient();
  // const { data: yourDiamondContract } = useScaffoldContract({
  //   contractName: "Diamond",
  //   walletClient,
  // });
  // const { contract } = useContract(deployedContractData?.address, deployedContractData?.abi);
  const [facets, setFacets] = useState<Facet[]>([]);
  const { targetNetwork } = useTargetNetwork();
  const publicClient = usePublicClient({ chainId: targetNetwork.id });
  // if (!diamondContractData || deployedContractLoading) return "Loading contracts...";
  const diamomdLoupe = getContract({
    address: diamondContractData?.address || "",
    abi: diamondLoupeData?.abi || [
      "function facets() external view returns (address[] memory)",
      "function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory)",
      "function facetAddresses() external view returns (address[] memory facetAddresses_)",
      "function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_)",
    ],
    walletClient: publicClient,
  });

  const diamomdCut = getContract({
    address: diamondContractData?.address || "",
    abi: diamondCutData?.abi || ["function diamondCut(bytes[] calldata _diamondCut) external"],
    walletClient: publicClient,
  });
  console.log(
    "facets: ",
    facets,
    "publicClient: ",
    publicClient,
    "diamondAddress: ",
    diamondContractData?.address,
    setFacets,
  );
  console.log("diamondLoupe: ", diamomdLoupe);
  console.log("diamondCut: ", diamomdCut);

  // console.log("diamondAddr: ", diamondAddress);
  //   const provider = new ethers.providers.Web3Provider(window.ethereum);
  //   const diamondCut = new ethers.Contract(
  //     diamondAddress,
  //     [
  //       "function diamondCut(bytes[] calldata _diamondCut) external",
  //       "function facets() external view returns (address[] memory facetAddresses, bytes4[] memory facetFunctionSelectors)",
  //     ],
  //     provider.getSigner(),
  //   );
  //   const diamondLoupe = new ethers.Contract(
  //     diamondAddress,
  //     [
  //       "function facets() external view returns (address[] memory)",
  //       "function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory)",
  //     ],
  //     provider.getSigner(),
  //   );
  //   const getFacets = async () => {
  //     const [facetAddresses, facetFunctionSelectors] = await diamondCut.facets();
  //     const facets: Facet[] = [];
  //     for (let i = 0; i < facetAddresses.length; i++) {
  //       const functionSelectors = await diamondLoupe.facetFunctionSelectors(facetAddresses[i]);
  //       facets.push({ address: facetAddresses[i], functionSelectors });
  //     }
  //     setFacets(facets);
  //   };
  return (
    <div>
      <h2>Hello world</h2>
      <button
        onClick={async () => {
          const res = await diamomdLoupe?.read.facetAddress(["0x1f931c1c"]);
          console.log("RES::", res);
        }}
      >
        {" "}
        Click me{" "}
      </button>
    </div>
  );
};
