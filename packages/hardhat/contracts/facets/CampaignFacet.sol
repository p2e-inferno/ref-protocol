// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/storage/AppConstants.sol";
import "../libraries/storage/LibAppStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import { AffiliateUplineData } from "../libraries/helpers/AffiliateHelpers.sol";
import { CampaignHelpers } from "../libraries/helpers/CampaignHelpers.sol";
import { AffiliateHelpers } from "../libraries/helpers/AffiliateHelpers.sol";
import "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";
import "./Campaign.sol";
import "../interfaces/ICampaignFacet.sol";
import "../libraries/Utilities.sol";
import "../libraries/Modifiers.sol";

// TODOs
/**
 * @title CampaignFacet
 * @dev Create and manage referral campaigns for locks
 * @author Danny Thomx
 * @notice This contract module allows the creation and operation of referral campaigns for lock contracts. 
 */
contract CampaignFacet is Modifiers, ICampaignFacet, ReentrancyGuard {

	event NewCampaign(
		address campaignId,
		address owner,
		address nftAddress,
		uint256[] commissionRate
	);
	event NewReferee(
		address indexed campaignId,
		address indexed _buyer,
		address referrer,
		uint256 tokenId
	);

	    /**
     * @dev Get campaign data for a specific lock
     * @param _lockAddress The address of the lock
     * @return campaignInfo The campaign details
     */
	function getCampaignForLock(
		address _lockAddress
	) external view returns (CampaignInfo memory) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		require(
			campaignStorage.lockToCampaignId[_lockAddress] != address(0),
			"No campaign exist for this lock"
		);
		address campaignId = campaignStorage.lockToCampaignId[_lockAddress];
		return campaignStorage.campaignsById[campaignId];
	}

    /**
     * @dev Get campaign commission balance
     * @param _campaignId The ID of the campaign
     * @param _tokenAddress The address of the token
     * @return balance The balance of commissions
     */
	function getCampaignCommissionBalance(
		address _campaignId,
		address _tokenAddress
	) external view returns (uint256 balance) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		bool isTokenRequest = _tokenAddress != address(0);
		return isTokenRequest ? campaignStorage.commissionTokenBalance[_campaignId][_tokenAddress]
			: campaignStorage.commissionEtherBalance[_campaignId];
	}

  	/**
     * @dev Get withdrawal delay for a specific campaign
     * @param _campaignId The address of the campaign
     * @return delayInDays The delay in days for withdrawal
     */
	function getWithdrawalDelayForCampaign(address _campaignId) external view returns (uint256 delayInDays) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		delayInDays = campaignStorage.withdrawalDelay[_campaignId];
	}

	  /**
     * @dev Get non-commission balance for a specific campaign
     * @param _campaignId The address of the campaign
     * @param _tokenAddress The address of the token
     * @return balance The non-commission balance
     */
	function getCampaignNonCommissionBalance(
		address _campaignId,
		address _tokenAddress
	) external view returns (uint256 balance) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		bool isTokenRequest = _tokenAddress != address(0);
		return isTokenRequest ? campaignStorage.nonCommissionTokenBalance[_campaignId][_tokenAddress]
			: campaignStorage.nonCommissionEtherBalance[_campaignId];
	}

   /**
     * @dev Check if a campaign exists
     * @param _campaignId The address of the campaign
     * @return isCampaign The boolean response if campaign exists
     */
	function getIsCampaign(
		address _campaignId
	) external view returns (bool isCampaign) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		isCampaign = campaignStorage.isCampaign[_campaignId];
	}

	  /**
     * @dev Get campaign data by ID
     * @param _campaignId The address of the campaign
     * @return campaignInfo The campaign details
     */
	function getCampaignById(
		address _campaignId
	) public view returns (CampaignInfo memory) {
		return CampaignHelpers._getCampaignData(_campaignId);
	}

	  /**
     * @dev Get the maximum tiers of campaigns
     * @return The max number of tiers
     */
	function getMaxTiers() external pure returns (uint) {
		return AppConstants.MAX_TIERS;
	}

	 /**
     * @dev Create a new campaign
     * @param _name The name of the campaign
     * @param _lockAddress The address of the lock
     * @param _level1Commission The level 1 commission
     * @param _level2Commission The level 2 commission
     * @param _level3Commission The level 3 commission
     * @param _delay The withdrawal delay
     */
	function createCampaign(
		string memory _name,
		address _lockAddress,
		uint256 _level1Commission,
		uint256 _level2Commission,
		uint256 _level3Commission,
		uint256 _delay
	) external {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		// check unadus is initialized
        require(appStorage.unadusAddress != address(0), "UNADUS not initialized");
		// check no campaign exists for this lock
		require(
			campaignStorage.lockToCampaignId[_lockAddress] == address(0),
			"Campaign exist for this lock"
		);
		// check user is a lock manager
		require(Utilities._isLockManager(_lockAddress), "Not Lock Manager");
	
		CampaignInfo memory _newCampaign;
		uint256[] memory tiersCommission = new uint256[](3);
		tiersCommission[0] = _level1Commission;
		tiersCommission[1] = _level2Commission;
		tiersCommission[2] = _level3Commission;
		// deploy campaign (onKeyPurchase) hook to track purchases for campaign
		CampaignHook newCampaignId = new CampaignHook(appStorage.unadusAddress, _lockAddress);
		// create new campaign
		_newCampaign.name = _name;
		_newCampaign.campaignId = address(newCampaignId);
		_newCampaign.tiersCommission = tiersCommission;
		_newCampaign.owner = msg.sender;
		_newCampaign.lockAddress = _lockAddress;
		_newCampaign.delay = _delay;

		// update isCampaignHook mapping for new campaign
		campaignStorage.isCampaign[address(newCampaignId)] = true;
		campaignStorage.lockToCampaignId[_lockAddress] = address(newCampaignId);

		// add campaign to campaign storage
		CampaignHelpers._addCampaign(_newCampaign);
		// set lock referral commission for this campaign
		uint256 totalCommission = CampaignHelpers._getTotalTiersCommission(
			_newCampaign
		);
		// set referrer fee for the lock and unadus as the referrer address
		IPublicLockV12(_lockAddress).setReferrerFee(appStorage.unadusAddress, totalCommission);
		// set CampaignHook as onKeyPurchaseHook for the lock
		IPublicLockV12(_lockAddress).setEventHooks(
			address(newCampaignId),
			address(0),
			address(0),
			address(0),
			address(0),
			address(0),
			address(0)
		);
		// add CampaignHook as lock manager
		IPublicLockV12(_lockAddress).addLockManager(address(newCampaignId));
		// emit NewCampaign event
		emit NewCampaign(
			address(newCampaignId),
			msg.sender,
			_lockAddress,
			tiersCommission
		);
	}
	
	/**
     * @dev Change the name of a specific campaign
     * @param _newName The new name
     * @param _campaignId The address of the campaign
     */
	function setName(
		string memory _newName,
		address _campaignId
	) external onlyCampaignOwner(_campaignId) {
		CampaignInfo memory _campaign = CampaignHelpers._getCampaignData(_campaignId);
		require(_campaign.owner == msg.sender, "Not Campaign owner");
		_campaign.name = _newName;
		CampaignHelpers._updateCampaignStorage(_campaign);
	}

	/**
     * @dev Set withdrawal delay for a specific campaign
     * @param _delayInDays The delay in days
     * @param _campaignId The address of the campaign
     */
	function setWithdrawalDelayForCampaign(
		uint256 _delayInDays,
		address _campaignId
	) external onlyCampaignOwner(_campaignId) {
		CampaignInfo memory _campaign = CampaignHelpers._getCampaignData(_campaignId);
		_campaign.delay = _delayInDays;
		CampaignHelpers._updateCampaignStorage(_campaign);
	}

	/**
     * @dev Set tiers commission
	 * @notice commission is expressed in basis points (ie 100% is 10000, 10% is 1000, 1% is 100)
     * @param _campaignId The address of the campaign
     * @param _level1Commission The level 1 commission
     * @param _level2Commission The level 2 commission
     * @param _level3Commission The level 3 commission
     */
	function setTiersCommission(
		address _campaignId,
		uint256 _level1Commission,
		uint256 _level2Commission,
		uint256 _level3Commission
	) external onlyCampaignOwner(_campaignId) {
		CampaignInfo memory _campaign = CampaignHelpers._getCampaignData(_campaignId);
		require(_campaign.campaignId != address(0), "Invalid CampaignId");
		require(_campaign.owner == msg.sender, "Not Campaign owner");
		uint256[] memory tiersCommission = new uint256[](3);
		tiersCommission[0] = _level1Commission;
		tiersCommission[1] = _level2Commission;
		tiersCommission[2] = _level3Commission;
		_campaign.tiersCommission = tiersCommission;
		CampaignHelpers._updateCampaignStorage(_campaign);
	}


    /**
     * @dev Process referred purchase
     * @param _purchaseData The data of the purchase
     * @return Boolean response of the operation
     */
	function onReferredPurchase(
		ReferredPurchaseData memory _purchaseData
	) external onlyCampaign returns (bool) {
		_addNewReferee(_purchaseData);

		// update affiliates' commission balance
		(
			address levelTwoReferrerAddress,
			address levelThreeReferrerAddress
		) = Utilities._getMultiLevelReferrers(_purchaseData.affiliateAddress, _purchaseData.campaignId);
		(
			uint256 levelOneShare,
			uint256 levelTwoShare,
			uint256 levelThreeShare
		) = AffiliateHelpers._calculateAffiliatesPayout(_purchaseData.commission, _purchaseData.campaignId);
		AffiliateUplineData memory affiliateData = AffiliateUplineData({
			campaignId: _purchaseData.campaignId,
			affiliateId: _purchaseData.affiliateAddress,
			levelTwoReferrer: levelTwoReferrerAddress,
			levelThreeReferrer: levelThreeReferrerAddress
		});
		AffiliateHelpers._updateAffiliateStorage(
			_purchaseData.tokenId,
			levelOneShare,
			_purchaseData.tokenAddress,
			_purchaseData.affiliateAddress,
			affiliateData
		);
		if (levelTwoReferrerAddress != address(0))
			AffiliateHelpers._updateAffiliateStorage(
				_purchaseData.tokenId,
				levelTwoShare,
				_purchaseData.tokenAddress,
				levelTwoReferrerAddress,
				affiliateData
			);
		if (levelThreeReferrerAddress != address(0))
			AffiliateHelpers._updateAffiliateStorage(
				_purchaseData.tokenId,
				levelThreeShare,
				_purchaseData.tokenAddress,
				levelThreeReferrerAddress,
				affiliateData
			);
		CampaignHelpers._updateCampaignPayoutData(
			_purchaseData.tokenAddress,
			levelOneShare,
			levelTwoShare,
			levelThreeShare,
			affiliateData
		);
		return true;
	}

	/**
     * @dev Process non-referred purchase
     * @param _campaignId The address of the campaign
     * @param _commission The commission amount
     * @param _tokenAddress The address of the token
     * @return Boolean response of the operation
     */
	function onNonReferredPurchase(
		address _campaignId,
		uint256 _commission,
		address _tokenAddress
	) external onlyCampaign returns (bool) {
		CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
		bool isTokenPurchase = _tokenAddress != address(0);
		isTokenPurchase ? campaignStorage.nonCommissionTokenBalance[_campaignId][_tokenAddress] += _commission 
			: campaignStorage.nonCommissionEtherBalance[_campaignId] += _commission;
		return true;
	}

	/**
	 * @dev Add a new referee
	 * @param _purchaseData The data of the purchase
	 */
	function _addNewReferee(ReferredPurchaseData memory _purchaseData) private {
		// emit new referee event
		emit NewReferee(_purchaseData.campaignId, _purchaseData.recipient, _purchaseData.affiliateAddress, _purchaseData.tokenId);
		// create new referee data
		RefereeInfo memory _newReferee;
		_newReferee.campaignId = _purchaseData.campaignId;
		_newReferee.id = _purchaseData.recipient;
		_newReferee.referrer = _purchaseData.affiliateAddress;
		_newReferee.keyPurchased = _purchaseData.tokenId;
		// update referee storage
		Utilities._updateRefereeStorage(_newReferee, _purchaseData.affiliateAddress);
		AffiliateHelpers._addAffiliateReferee(
			_purchaseData.affiliateAddress,
			_purchaseData.campaignId,
			_purchaseData.recipient
		);
	}

}