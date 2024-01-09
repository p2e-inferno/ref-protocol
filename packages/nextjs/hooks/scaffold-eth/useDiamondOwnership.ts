import { useEffect, useState } from "react";
import { usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

/**
 * Retrieves the diamondOwner facet instance.
 */
export function useDiamondOwnership() {
  const { targetNetwork } = useTargetNetwork();
  const { data: diamondContractData } = useDeployedContractInfo("Diamond");
  const { data: diamondOwnershipData } = useDeployedContractInfo("OwnershipFacet");
  const publicClient = usePublicClient({ chainId: targetNetwork.id });
  const [diamondOwner, setDiamondOwner] = useState<any>();

  useEffect(() => {
    if (!diamondOwnershipData || !diamondContractData) return;
    const diamondOwnership = getContract({
      address: diamondContractData.address,
      abi: diamondOwnershipData.abi,
      walletClient: publicClient,
    });
    setDiamondOwner(diamondOwnership);
  }, [diamondOwnershipData, diamondContractData, publicClient]);

  return diamondOwner;
}
