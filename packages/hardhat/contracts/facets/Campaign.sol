// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "../interfaces/ICampaignFacet.sol";

/******************************************************
 * Purpose
 * deploy onKeyPurchase hook to track referrals for a lock
 * *******************************************************
 */
contract CampaignHook {
    address campaignId = address(this);
    address immutable public UNADUS;
    address public nftAddressForCampaign;    

    constructor(address _UNADUS, address _lockAddress) { 
        nftAddressForCampaign = _lockAddress;
        UNADUS = _UNADUS;
    }

    function getReferrerFee(address _referrer)view public returns (uint256 referrerFees){
        return referrerFees = IPublicLockV12(nftAddressForCampaign).referrerFees(_referrer);
    }

    function getCampaignId() external view returns (address) {
        return campaignId;
    }

    /**
     * Price is the same for everyone... 
     * but we fail if signer of data does not match the lock's password.
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
     * No-op but required for the hook to work
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
        // decode affiliate's address from calldata
        address _affiliateAddress = abi.decode(_data, (address));

        // Determine if this was a referred or non-referred purchase
        bool isReferredPurchase = (_affiliateAddress != address(0) && _affiliateAddress != _recipient);
        
        bool isDone;
        if (isReferredPurchase) {
            isDone = ICampaignFacet(UNADUS).onReferredPurchase(campaignId, _tokenId, _recipient, _affiliateAddress, commission);
        } else {
            isDone = ICampaignFacet(UNADUS).onNonReferredPurchase(campaignId, commission);
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