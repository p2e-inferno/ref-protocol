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
  const unadusAddress = "0xA68195FA3DC7b3ACf195212767d0EfbD3F15F03E";
  const currentCampaignId = "0x362D8c6A77f4B8bC5A6224122bc8ef4d5B20A4dd";
  const currentLockAddress = "0x49d9d5da131dcf47900590a4beebbc939fb89f4a"; //0x49d9d5da131dcf47900590a4beebbc939fb89f4a :USDC | 0x924dDECF7b679765D8810e82d0A124eE4FbC31f5 :ETH
  const zeroAddress = "0x0000000000000000000000000000000000000000";
  const currentReferrer = "0xE11Cd5244DE68D90755a1d142Ab446A4D17cDC10";
  const currentCampaignName = "FERNO VIBES: Genesis";
  const tokenAddress = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"; // USDC Sepolia
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
      const isCampaignFacetManager = publicLockContract.isLockManager(campaignFacetAddress);
      const isUnadusManager = publicLockContract.isLockManager(unadusAddress);
      if (!isUnadusManager) await publicLockContract.addLockManager(unadusAddress);
      if (!isCampaignFacetManager) await publicLockContract.addLockManager(campaignFacetAddress);
      const campaignContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      // const params = {
      //   currentCampaignName,
      //   currentLockAddress,
      //   tierOneReward,
      //   tierTwoReward,
      //   tierThreeReward,
      //   withdrawalDelay,
      // };
      const tx = await campaignContract.createCampaign(
        currentCampaignName,
        currentLockAddress,
        tierOneReward,
        tierTwoReward,
        tierThreeReward,
        withdrawalDelay,
      );
      console.log("txX::createCampaign", tx);
    } catch (e) {
      console.log("CREATECAMPAIGN_ERR::", e);
    }
  };

  const checkout = async () => {
    const publicLockContract = new ethers.Contract(currentLockAddress, PublicLockV13.abi, signer);
    const amount = await publicLockContract.keyPrice();
    const purchaseParams = [
      [amount],
      [address],
      [unadusAddress],
      [ethers.constants.AddressZero],
      // [[]],
      // [ethers.utils.defaultAbiCoder.encode(["address"], ["0x8fa4bfbb396a76ebf79379c59f597867cf880ac4"])],
      // [ethers.utils.defaultAbiCoder.encode(["address"], ["0xC1eA63E3596599d186D80F07A8099047Fa49A901"])],
      [ethers.utils.defaultAbiCoder.encode(["address"], [currentReferrer])],
      // [ethers.utils.defaultAbiCoder.encode(["address"], [ethers.constants.AddressZero])],
    ];
    const options = {
      value: amount,
      gasLimit: 3000000,
    };
    const tx = await publicLockContract.purchase(...purchaseParams, options);
    // const tx = await publicLockContract.purchase(...purchaseParams);
    console.log("txn::purchase", tx);
  };

  const erc20Contract = new ethers.Contract(tokenAddress, erc20ABI, signer);
  // console.log("XX", erc20Contract);

  const tokenCheckout = async () => {
    const publicLockContract = new ethers.Contract(currentLockAddress, PublicLockV13.abi, signer);
    const amount = await publicLockContract.keyPrice();
    // approve token for transfer
    // const txn = await erc20Contract.approve(currentLockAddress, amount);
    await erc20Contract.approve(currentLockAddress, amount);
    // await txn.wait();
    checkout();
  };

  const becomeAffiliate = async () => {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, affiliateAbi, signer);
      const tx = await campaignContract.becomeAffiliate(zeroAddress, currentCampaignId);
      console.log("txX::becomeAffiliate", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  };

  const setName = async () => {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setName(currentCampaignName);
      console.log("txX::setName", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
    }
  };

  async function setTiersCommission() {
    try {
      const campaignContract = new ethers.Contract(unadusAddress, campaignAbi, signer);
      // const tx = await campaignContract.becomeAffiliate("0xca7632327567796e51920f6b16373e92c7823854");
      const tx = await campaignContract.setTiersCommission(currentCampaignId, 2000, 5000, 3000);
      console.log("txX::setName", tx);
    } catch (e) {
      console.log("AFFILIATE_ERR::", e);
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
        <div>
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
