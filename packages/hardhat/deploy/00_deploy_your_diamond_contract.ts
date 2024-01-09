import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
// import { getSelectors, FacetCutAction } from "./libraries/diamond.js";

interface ThisInterface {
  contract: {
    interface: {
      getSighash: (fnName: string) => number;
    };
  };
  filter: (v: (param: any) => boolean) => any[];
  remove: () => void;
  get: () => void;
}

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one t
/*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // await deploy("YourDiamondContract", {
  //   from: deployer,
  //   // Contract constructor arguments
  //   args: [deployer],
  //   log: true,
  //   // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
  //   // automatically mining the contract deployment transaction. There is no effect on live networks.
  //   autoMine: true,
  // });
  // Deploy YourDiamondContract
  const FacetCutAction: any = { Add: 0, Replace: 1, Remove: 2 };
  function getSelectors(contract: any) {
    const signatures = Object.keys(contract.interface.functions);
    const selectors = signatures.reduce((acc: any, val: any) => {
      if (val !== "init(bytes)") {
        acc.push(contract.interface.getSighash(val));
      }
      return acc;
    }, []);
    selectors.contract = contract;
    selectors.remove = remove;
    selectors.get = get;
    return selectors;
  }

  function remove(this: ThisInterface, functionNames: any) {
    const selectors: any = this.filter(v => {
      for (const functionName of functionNames) {
        if (v === this.contract.interface.getSighash(functionName)) {
          return false;
        }
      }
      return true;
    });
    selectors.contract = this.contract;
    selectors.remove = this.remove;
    selectors.get = this.get;
    return selectors;
  }

  function get(this: ThisInterface, functionNames: any) {
    const selectors: any = this.filter(v => {
      for (const functionName of functionNames) {
        if (v === this.contract.interface.getSighash(functionName)) {
          return true;
        }
      }
      return false;
    });
    selectors.contract = this.contract;
    selectors.remove = this.remove;
    selectors.get = this.get;
    return selectors;
  }
  // Get the deployed contract
  // const yourContract = await hre.ethers.getContract("YourContract", deployer);
  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  const DiamondInit = await hre.ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  console.log("DiamondInit deployed:", diamondInit.address);

  // set the `facetCuts` variable

  const FacetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  for (const FacetName of FacetNames) {
    // const Facet = await hre.ethers.getContractFactory(FacetName);
    await deploy(FacetName, {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });
    const facet = await hre.ethers.getContract(FacetName, deployer);
    console.log(`${FacetName} deployed: ${facet.address}`);
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  const functionCall = diamondInit.interface.encodeFunctionData("init");

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    owner: deployer,
    init: diamondInit.address,
    initCalldata: functionCall,
  };

  // deploy Diamond
  await deploy("Diamond", {
    from: deployer,
    args: [facetCuts, diamondArgs],
    log: true,
    autoMine: true,
  });
  const diamond = await hre.ethers.getContract("Diamond", deployer);

  // logging the address of the diamond
  console.log("Diamond deployed:", diamond.address);
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["YourDiamondContract"];
