import { usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

/**
 * Retrieves the diamondCut facet instance.
 */
export function useDiamondCut() {
  const { targetNetwork } = useTargetNetwork();
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { data: diamondCutData } = useDeployedContractInfo("DiamondCutFacet");
  const publicClient = usePublicClient({ chainId: targetNetwork.id });

  const diamondCut = getContract({
    address: diamondContractData?.address || "",
    abi: diamondCutData?.abi || ["function diamondCut(bytes[] calldata _diamondCut) external"],
    walletClient: publicClient,
  });

  return diamondCut;
}
