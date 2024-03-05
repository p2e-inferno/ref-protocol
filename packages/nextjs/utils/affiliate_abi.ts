export const affiliateAbi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "affiliate",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "campaignId",
        type: "address",
      },
    ],
    name: "NewAffiliate",
    type: "event",
  },
  {
    inputs: [],
    name: "allAffiliates",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_referrer",
        type: "address",
      },
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "becomeAffiliate",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_affiliateId",
        type: "address",
      },
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "getAffiliateInfo",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "campaignId",
            type: "address",
          },
          {
            internalType: "address",
            name: "affiliateId",
            type: "address",
          },
          {
            internalType: "address",
            name: "referrer",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "balance",
            type: "uint256",
          },
        ],
        internalType: "struct AffiliateInfo",
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
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "getAffiliatesOf",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "campaignId",
            type: "address",
          },
          {
            internalType: "address",
            name: "affiliateId",
            type: "address",
          },
          {
            internalType: "address",
            name: "referrer",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "balance",
            type: "uint256",
          },
        ],
        internalType: "struct AffiliateInfo[]",
        name: "",
        type: "tuple[]",
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
    ],
    name: "getCampaignAffiliates",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "campaignId",
            type: "address",
          },
          {
            internalType: "address",
            name: "affiliateId",
            type: "address",
          },
          {
            internalType: "address",
            name: "referrer",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "balance",
            type: "uint256",
          },
        ],
        internalType: "struct AffiliateInfo[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_affiliate",
        type: "address",
      },
      {
        internalType: "address",
        name: "_campaignId",
        type: "address",
      },
    ],
    name: "getRefereesOf",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "isCampaignAffiliate",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];
