import { usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

/**
 * Retrieves the diamondLoupe facet instance.
 */
export function useDiamondLoupe() {
  const { targetNetwork } = useTargetNetwork();
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { data: diamondLoupeData } = useDeployedContractInfo("DiamondLoupeFacet");
  const publicClient = usePublicClient({ chainId: targetNetwork.id });

  const diamondLoupe = getContract({
    address: diamondContractData?.address || "",
    abi: diamondLoupeData?.abi || [
      "function facets() external view returns (address[] memory)",
      "function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory)",
    ],
    walletClient: publicClient,
  });

  return diamondLoupe;
}
