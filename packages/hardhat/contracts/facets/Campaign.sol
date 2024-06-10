// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "../interfaces/ICampaignFacet.sol";

error InvalidAddress();

/******************************************************
 * Purpose
 * deploy onKeyPurchase hook to track referrals for a lock
 * *******************************************************
 */
contract CampaignHook {
     /**
     * @dev The length of an Ethereum address
     */
    uint256 constant ADDRESS_BYTES_LENGTH = 20;

     /**
     * @dev A unique identifier for a campaign. It is set to the address of the contract.
     */
    address campaignId = address(this);
    /**
     * @dev UNADUS contract address, which is immutable.
     */
    address immutable public UNADUS;
    /**
     * @dev The address of the NFT contract that is being used for the campaign.
     */
    address public nftAddressForCampaign; 
    /**
     * @dev Initializes the UNADUS and lock addresses for the contract.
     * @param _UNADUS The address of UNADUS contract.
     * @param _lockAddress The address of the lock.
     */
    constructor(address _UNADUS, address _lockAddress) { 
        nftAddressForCampaign = _lockAddress;
        UNADUS = _UNADUS;
    }

     /**
     * @dev Retrieves the referral fees of a lock for a given referrer.
     * @param _referrer The address of the referrer.
     * @return referrerFees The fees paid to the referrer.
     */
    function getReferrerFee(address _referrer)view public returns (uint256 referrerFees){
        return referrerFees = IPublicLockV12(nftAddressForCampaign).referrerFees(_referrer);
    }

     /**
     * @dev Retrieves the campaign ID.
     * @return Address of the campaign.
     */
    function getCampaignId() external view returns (address) {
        return campaignId;
    }

    /**
     * @dev Calculate the price of a key purchase for a lock.
     * @return minKeyPrice The minimum price for a key.
     */
    function keyPurchasePrice(
        address, /* from */
        address,
        address, /* referrer */
        bytes calldata /* data */
    ) external virtual view returns (uint256 minKeyPrice) {
        minKeyPrice = IPublicLockV12(msg.sender).keyPrice();
    }

     /**
     * @dev Executes whenever there is a key purchase for a lock.
     * @param _tokenId The ID of the token.
     * @param _recipient The address of the recipient.
     * @param _referrer The address of the referrer.
     * @param _data The data to be passed along with the key purchase.
     * @param _keyPrice The price of the key.
     */
    function onKeyPurchase(
        uint256 _tokenId, /* tokenId */
        address, /* from */
        address _recipient, /* recipient */
        address _referrer, /* referrer */
        bytes calldata _data, /* data */
        uint256 _keyPrice, /* minKeyPrice */
        uint256 /* pricePaid */
    ) external {
        // calculate referrer commission for the lock
        uint256 commission = _calculateCampaignCommission(_referrer, _keyPrice);
        uint256 dataLength = _data.length;
        if(dataLength > 0 && dataLength != ADDRESS_BYTES_LENGTH) revert InvalidAddress();
        // decode affiliate's address from calldata
        address _affiliateAddress = _data.length == 0 ? address(0) : abi.decode(_data, (address));

        // Determine if this was a referred or non-referred purchase
        bool isReferredPurchase = (_affiliateAddress != address(0) && _affiliateAddress != _recipient);
        address tokenAddress = IPublicLockV12(nftAddressForCampaign).tokenAddress();
        bool isDone;
        if (isReferredPurchase) {
            ReferredPurchaseData memory _purchaseData =  ReferredPurchaseData({
                campaignId: campaignId,
                tokenId: _tokenId,
                recipient: _recipient,
                affiliateAddress: _affiliateAddress,
                commission: commission,
                tokenAddress: tokenAddress
            });

            isDone = ICampaignFacet(UNADUS).onReferredPurchase(_purchaseData);
        } else {
            isDone = ICampaignFacet(UNADUS).onNonReferredPurchase(campaignId, commission, tokenAddress);
        }
        
        require(isDone, "Failed CampaignFacet call");
        return;
    }

    /**
     * @notice Calculates the referral fee received by the specified _referrer
     * @param _referrer Address of the referrer to receive commission
     * @param _keyPrice Price of the NFT
     */
    function _calculateCampaignCommission(address _referrer, uint256 _keyPrice)private view returns (uint256 commission) {
        uint256 referrerFees = getReferrerFee(_referrer);
        if (referrerFees > 0) {
            commission = (_keyPrice * referrerFees) / 10000;
            return commission;
        }
        return 0;
    }

}