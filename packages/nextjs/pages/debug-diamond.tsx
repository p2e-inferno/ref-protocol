import { useEffect } from "react";
// import abis from "@unlock-protocol/contracts";
import { PublicLockV13 } from "@unlock-protocol/contracts";
// import networks from "@unlock-protocol/networks";
// import { Paywall } from "@unlock-protocol/paywall";
import { ethers } from "ethers";
import type { NextPage } from "next";
import { useLocalStorage } from "usehooks-ts";
import { useAccount } from "wagmi";
import { erc20ABI } from "wagmi";
// import { useContractWrite } from "wagmi";
import { MetaHeader } from "~~/components/MetaHeader";
import { DiamondContractUI } from "~~/components/diamond/DiamondContractUI";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { affiliateAbi } from "~~/utils/affiliate_abi";
import { campaignAbi } from "~~/utils/campaign_abi";
import { useEthersSigner } from "~~/utils/ethers";
// import { useEthersProvider } from "~~/utils/ethers-provider";
import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getContractNames } from "~~/utils/scaffold-eth/contractNames";

const selectedContractStorageKey = "scaffoldEth2.selectedContract";
const contractNames = getContractNames();

const DebugDiamond: NextPage = () => {
  const [selectedContract, setSelectedContract] = useLocalStorage<ContractName>(
    selectedContractStorageKey,
    contractNames[0],
  );
  const { address } = useAccount();
  const { data: campaignFacetContract } = useDeployedContractInfo("CampaignFacet");

  const signer = useEthersSigner();
  const unadusAddress = "0x71c284187D759e64bE7d0B98bc959c846E9aE38A";
  const currentCampaignId = "0x4d439635950Cd38A4BEDf754990ce5912b361FE8";
  const currentLockAddress = "0x924dDECF7b679765D8810e82d0A124eE4FbC31f5"; //0x49d9d5da131dcf47900590a4beebbc939fb89f4a :USDC | 0x924dDECF7b679765D8810e82d0A124eE4FbC31f5 :ETH | 0x4e6c4F1797633bcCBeD7a70648BC418a9EC65fBF :ETH
  const zeroAddress = "0x0000000000000000000000000000000000000000";
  const currentReferrer = "0x8fa4bfbb396a76ebf79379c59f597867cf880ac4"; //0xE11Cd5244DE68D90755a1d142Ab446A4D17cDC10 | 0x8fa4bfbb396a76ebf79379c59f597867cf880ac4 | 0xC1eA63E3596599d186D80F07A8099047Fa49A901
  const currentCampaignName = "ETH Campaign"; // "TokenCampaign" | "ETH Campaign" | "MEMBERS Campaign"
  const tokenAddress = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"; // USDC Sepolia
  const membershipLockAddress = "0x4e6c4F1797633bcCBeD7a70648BC418a9EC65fBF";
  const BASIS_POINTS = 100;
  const tierOneReward = 10 * BASIS_POINTS;
  const tierTwoReward = 7 * BASIS_POINTS;
  const tierThreeReward = 3 * BASIS_POINTS;
  const withdrawalDelay = 0;
  const campaignFacetAddress = campaignFacetContract?.address || zeroAddress;

  const createCampaign = async () => {
    if (campaignFacetAddress === zeroAddress) return "ADDRESS_ERR:: Invalid CampaignFacet address";
    try {
      const publicLockContract = new ethers.Contract(currentLockAddress, PublicLockV13.abi, signer);
      const isCampaignFacetManager = await publicLockContract.isLockManager(campaignFacetAddress);
      const isUnadusManager = await publicLockContract.isLockManager(unadusAddress);
      if (isUnadusManager === false) await publicLockContract.addLockManager(unadusAddress);
      if (!isCampaignFacetManager === false) await publicLockContract.addLockManager(campaignFacetAddress);
      const unadusCampaignFacetContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      const params = [
        currentCampaignName,
        currentLockAddress,
        tierOneReward,
        tierTwoReward,
        tierThreeReward,
        withdrawalDelay,
      ];
      const options = {
        gasLimit: 3000000,
      };
      const tx = await unadusCampaignFacetContract.createCampaign(...params, options);
      console.log("createCampaign", tx);
    } catch (e) {
      console.log("CREATECAMPAIGN_ERR::", e);
    }
  };

  const subscribeMembership = async () => {
    try {
      const publicLockContract = new ethers.Contract(membershipLockAddress, PublicLockV13.abi, signer);
      const hasValidMembership = await publicLockContract.getHasValidKey(address);
      if (!hasValidMembership) {
        const tx = await _checkout(membershipLockAddress, true);
        console.log("Subscription::", tx);
        return;
      }
      return console.log("Subscription:: Already a member :-)...");
    } catch (e) {
      console.log("SUBSCRIPTION_ERR::", e);
    }
  };

  const checkout = async () => {
    await _checkout(currentLockAddress, false);
  };

  const _checkout = async (lockAddress: string, isMembership: boolean) => {
    const publicLockContract = new ethers.Contract(lockAddress, PublicLockV13.abi, signer);
    const amount = await publicLockContract.keyPrice();
    const purchaseParams = [
      [amount],
      [address],
      [unadusAddress],
      [ethers.constants.AddressZero],
      // [[]],
      // [ethers.utils.defaultAbiCoder.encode(["address"], ["0x8fa4bfbb396a76ebf79379c59f597867cf880ac4"])],
      // [ethers.utils.defaultAbiCoder.encode(["address"], ["0xC1eA63E3596599d186D80F07A8099047Fa49A901"])],
      [isMembership ? [] : ethers.utils.defaultAbiCoder.encode(["address"], [currentReferrer])],
      // [ethers.utils.defaultAbiCoder.encode(["address"], [ethers.constants.AddressZero])],
    ];
    const options = {
      value: amount,
      gasLimit: 3000000,
    };
    const tx = await publicLockContract.purchase(...purchaseParams, options);
    console.log("txn::purchase", tx);
  };

  const erc20Contract = new ethers.Contract(tokenAddress, erc20ABI, signer);

  const tokenCheckout = async () => {
    const publicLockContract = new ethers.Contract(currentLockAddress, PublicLockV13.abi, signer);
    const amount = await publicLockContract.keyPrice();
    // approve token for transfer
    await erc20Contract.approve(currentLockAddress, amount);
    // const txn = await erc20Contract.approve(currentLockAddress, amount);
    // await txn.wait();
    checkout();
  };

  const becomeAffiliate = async () => {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, affiliateAbi, signer);
      const tx = await campaignContract.becomeAffiliate(zeroAddress, currentCampaignId);
      console.log("becomeAffiliate", tx);
    } catch (e) {
      console.log("BECOME_AFFILIATE_ERR::", e);
    }
  };

  const setName = async () => {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setName(currentCampaignName);
      console.log("setName:", tx);
    } catch (e) {
      console.log("SET_NAME_ERR::", e);
    }
  };

  async function setTiersCommission() {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      const tx = await campaignContract.setTiersCommission(
        currentCampaignId,
        tierOneReward,
        tierTwoReward,
        tierThreeReward,
      );
      console.log("setTiersCommission:", tx);
    } catch (e) {
      console.log("SET_TIERS_ERR::", e);
    }
  }

  useEffect(() => {
    if (!contractNames.includes(selectedContract)) {
      setSelectedContract(contractNames[0]);
    }
  }, [selectedContract, setSelectedContract]);

  return (
    <>
      <MetaHeader
        title="Debug Diamond Contracts | Scaffold-ETH 2"
        description="Debug your deployed 🏗 Scaffold-ETH 2 diamond contracts in an easy way"
      />
      <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
        {contractNames.length === 0 ? (
          <p className="text-3xl mt-14">No contracts found!</p>
        ) : (
          <>
            {contractNames.length > 1 && (
              <div className="flex flex-row gap-2 w-full max-w-7xl pb-1 px-6 lg:px-10 flex-wrap">
                {contractNames.map(contractName => (
                  <button
                    className={`btn btn-secondary btn-sm font-thin ${
                      contractName === selectedContract ? "bg-base-300" : "bg-base-100"
                    }`}
                    key={contractName}
                    onClick={() => setSelectedContract(contractName)}
                  >
                    {contractName}
                  </button>
                ))}
              </div>
            )}
            {contractNames.map(contractName => (
              <>
                <DiamondContractUI
                  key={contractName}
                  contractName={contractName}
                  className={contractName === selectedContract ? "" : "hidden"}
                />
              </>
            ))}
          </>
        )}
      </div>
      <div className="text-center mt-8 bg-secondary p-10">
        <div className="mb-3">
          <button onClick={becomeAffiliate} className="btn btn-sm">
            Become Affiliate
          </button>
          <button onClick={createCampaign} className="ml-2 btn btn-accent btn-sm">
            Create Campaign
          </button>
          <button onClick={setName} className="hidden ml-2 btn btn-accent btn-sm">
            Set Name
          </button>
          <button onClick={setTiersCommission} className="hidden ml-2 btn btn-accent btn-sm">
            Set Tiers
          </button>
          <button onClick={checkout} className="ml-2 btn btn-accent btn-sm">
            Checkout
          </button>
          <button onClick={tokenCheckout} className="btn btn-sm">
            Token Checkout
          </button>
        </div>
        <div>
          <button onClick={subscribeMembership} className="btn btn-sm">
            Subscribe Membership
          </button>
        </div>
        <h1 className="text-4xl my-0">Debug Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            packages / nextjs / pages / debug-diamond.tsx
          </code>{" "}
        </p>
      </div>
    </>
  );
};

export default DebugDiamond;
