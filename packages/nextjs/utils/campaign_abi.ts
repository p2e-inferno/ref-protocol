export const campaignAbi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "campaignId",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "nftAddress",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "commissionRate",
        type: "uint256[]",
      },
    ],
    name: "NewCampaign",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "campaignId",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_buyer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "referrer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "NewReferee",
    type: "event",
  },
  {
    inputs: [],
    name: "UNADUS",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "address",
        name: "_lockAddress",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_level1Commission",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_level2Commission",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_level3Commission",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_delay",
        type: "uint256",
      },
    ],
    name: "createCampaign",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "getCampaignData",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "name",
            type: "string",
          },
          {
            internalType: "address",
            name: "campaignId",
            type: "address",
          },
          {
            internalType: "address",
            name: "owner",
            type: "address",
          },
          {
            internalType: "address",
            name: "lockAddress",
            type: "address",
          },
          {
            internalType: "uint256[]",
            name: "tiersCommission",
            type: "uint256[]",
          },
          {
            internalType: "uint256",
            name: "commissionBalance",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "nonCommissionBalance",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "delay",
            type: "uint256",
          },
        ],
        internalType: "struct CampaignInfo",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_lockAddress",
        type: "address",
      },
    ],
    name: "getCampaignForLock",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "name",
            type: "string",
          },
          {
            internalType: "address",
            name: "campaignId",
            type: "address",
          },
          {
            internalType: "address",
            name: "owner",
            type: "address",
          },
          {
            internalType: "address",
            name: "lockAddress",
            type: "address",
          },
          {
            internalType: "uint256[]",
            name: "tiersCommission",
            type: "uint256[]",
          },
          {
            internalType: "uint256",
            name: "commissionBalance",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "nonCommissionBalance",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "delay",
            type: "uint256",
          },
        ],
        internalType: "struct CampaignInfo",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getMaxTiers",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_UNADUSAddress",
        type: "address",
      },
    ],
    name: "initUNADUS",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "lockToCampaignId",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_commission",
        type: "uint256",
      },
    ],
    name: "onNonReferredPurchase",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_recipient",
        type: "address",
      },
      {
        internalType: "address",
        name: "_affiliateAddress",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_commission",
        type: "uint256",
      },
    ],
    name: "onReferredPurchase",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_newName",
        type: "string",
      },
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "setName",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_level1Commission",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_level2Commission",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_level3Commission",
        type: "uint256",
      },
    ],
    name: "setTiersCommission",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];
