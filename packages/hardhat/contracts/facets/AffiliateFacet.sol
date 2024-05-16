// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/storage/LibRefereeStorage.sol";
import "../libraries/storage/LibAffiliateStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import "../libraries/storage/LibAppStorage.sol";

/**
 * @title AffiliateFacet
 * @dev Handles functionalities related to campaign affiliates.
 */
contract AffiliateFacet {
	mapping(address => mapping(address => bool)) isCampaignAffiliate;
	event NewAffiliate(address indexed affiliate, address campaignId);

	/**
	 * @dev Get a list of all affiliates associated with a campaign.
	 * @param _campaignId The campaign to fetch the affiliates.
	 * @return campaignAffiliates List of all affiliates.
	 */
	function getCampaingAffiliates(address _campaignId) external view returns (address[] memory campaignAffiliates) {
		AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
		campaignAffiliates = affiliateStorage.affiliatesOf[_campaignId];
	}

	/**
	 * @dev Get a list of all referees associated with an affiliate for a specific campaign.
	 * @param _affiliate The affiliate to fetch the referees.
	 * @param _campaignId The campaign to fetch the referees.
	 * @return List of all referees.
	 */
	function getRefereesOf(
		address _affiliate,
		address _campaignId
	) external view returns (address[] memory) {
		AffiliateStorage storage _storage = LibAffiliateStorage
			.diamondStorage();
		return _storage.refereesOf[_affiliate][_campaignId];
	}

	/**
   * @dev Get count of affiliates associated with a campaign.
   * @param _campaignId The campaign to fetch the affiliate count.
   * @return count Number of affiliates.
   */
	function getCampaignAffiliatesCount(address _campaignId)external view returns(uint256 count) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
	    count =  _storage.affiliatesOf[_campaignId].length;
	}

/**
   * @dev Get status of an affiliate association with a campaign.
   * @param _affiliate The affiliate to fetch the status.
   * @param _campaignId The campaign to fetch the status.
   * @return Boolean indicating if the account is an affiliate of the campaign.
   */
	function getIsCampaignAffiliate(
		address _affiliate,
		address _campaignId
	) external view returns (bool) {
		return isCampaignAffiliate[_affiliate][_campaignId];
	}

 /**
   * @dev Get affiliate referrer associated with a campaign.
   * @param _affiliateId The affiliate to fetch the referrer.
   * @param _campaignId The campaign to fetch the referrer.
   * @return referrer The referrer of the affiliate for the campaign.
   */
	function getAffiliateReferrer(address _affiliateId, address _campaignId) external view returns(address referrer) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        referrer = _storage.affiliateData[_affiliateId][_campaignId].referrer;
	}

	  /**
   * @dev Get affiliate ether balance for a campaign.
   * @param _affiliateId The affiliate to fetch the balance.
   * @param _campaignId The campaign to fetch the balance.
   * @return balance Ether balance of the affiliate for the campaign.
   */
	function getAffiliateEthBalanceForCampaign(address _affiliateId, address _campaignId)view external returns (uint256 balance) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
		balance = _storage.affiliateBalance[_affiliateId].etherBalance[_campaignId];
	}
   
   /**
   * @dev Get affiliate token balance for a campaign.
   * @param _affiliateId The affiliate to fetch the balance.
   * @param _campaignId The campaign to fetch the balance.
   * @param _tokenAddress Ethereum address of the token.
   * @return balance Token balance of the affiliate for the campaign.
   */
	function getAffiliateTokenBalanceForCampaign(address _affiliateId, address _campaignId, address _tokenAddress) view external returns (uint256 balance) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
 		balance = _storage.affiliateBalance[_affiliateId].tokenBalance[_campaignId][_tokenAddress];
	}

	/**
	 * @dev Get an array of ids of tokens sold by an affiliate in a campaign.
	 * @param _affiliateId Ethereum address of the affiliate.
	 * @param _campaignId Ethereum address of the campaign.
	 * @return soldTokens list by the affiliate.
	 */
	function getAffiliateSoldTokens(address _affiliateId, address _campaignId) external view returns(uint256[] memory soldTokens) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        soldTokens = _storage.affiliateData[_affiliateId][_campaignId].soldTokens;
	}

	/**
	 * @dev Get an array of ids of tokens sold by the downline of an affiliate in a campaign.
	 * @param _affiliateId Ethereum address of the affiliate.
	 * @param _campaignId Ethereum address of the campaign.
	 * @return soldTokens list by the affiliate's downlines.
	 */
	function getAffiliateDownlineSoldTokens(address _affiliateId, address _campaignId) external view returns(uint256[] memory soldTokens) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        soldTokens = _storage.affiliateData[_affiliateId][_campaignId].refereesSoldTokens;
	}

	/**
	 * @dev Get information about a sale made by an affiliate in a campaign
	 * @param _affiliateId Ethereum address of the affiliate.
	 * @param _campaignId Ethereum address of the campaign.
	 * @param _tokenId Token ID for which the sale data is needed.
	 * @return saleInfo Sale information for given tokenId.
	 */
	function getAffiliateSaleData(address _affiliateId, address _campaignId, uint256 _tokenId) external view returns(SaleInfo memory saleInfo) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        saleInfo = _storage.affiliateData[_affiliateId][_campaignId].saleData[_tokenId];
	}

	/**
	 * @dev A user becomes an affiliate of a campaign. If a referrer is provided, affiliate is linked to the referrer.
	 * @param _referrer Ethereum address of the referrer. This is optional.
	 * @param _campaignId Ethereum address of the campaign.
	*/
	function becomeAffiliate(address _referrer, address _campaignId) external {
		CampaignStorage storage _storage = LibCampaignStorage.diamondStorage();
		address campaignId = _storage.campaignsById[_campaignId].campaignId;
		bool isValidCampaign = campaignId != address(0);
		require(isValidCampaign, "Invalid Campaign ID");
		// check _referrer is an affiliate
		if (_referrer != address(0)) {
			require(
				isCampaignAffiliate[_referrer][_campaignId] == true,
				"Referrer NOT an Affiliate of this Campaign"
			);
		}
		// check if user is already an affiliate
		require(
			isCampaignAffiliate[msg.sender][_campaignId] == false,
			"Already an Affiliate in this Campaign"
		);
		
		// set new affiliate data
        _addNewAffiliate(_campaignId, msg.sender, _referrer);
		_setIsAffiliate(msg.sender, _campaignId, true);
		emit NewAffiliate(msg.sender, _campaignId);
	}

	/**
	 * @dev Add a new affiliate to a campaign and update the referrer's list of referees and the list of all affiliates.
	 * @param _campaignId Ethereum address of the campaign.
	 * @param _affiliateId Ethereum address of the new affiliate.
	 * @param _referrer Ethereum address of the referrer. This is optional.
	*/
	function _addNewAffiliate(
        address _campaignId,
        address _affiliateId,
		address _referrer
	) private {
		AffiliateStorage storage _affiliateStorage = LibAffiliateStorage.diamondStorage();
		// add new affiliate to referrer's list of referees for this campaign
		if (_referrer != address(0))
			_affiliateStorage.refereesOf[_referrer][_campaignId].push(
				_affiliateId
			);
        
		// update this campaign's affiliates list
		_affiliateStorage.affiliatesOf[_campaignId].push(_affiliateId);

		// set affiliate data for this campaign
		_affiliateStorage.affiliateData[_affiliateId][_campaignId].campaignId = _campaignId;
		_affiliateStorage.affiliateData[_affiliateId][_campaignId].affiliateId = _affiliateId;
		_affiliateStorage.affiliateData[_affiliateId][_campaignId].referrer = _referrer;
		// check if affiliate already in allAffiliate list else add to allAffiliates list
		AppStorage storage _appStorage = LibAppStorage.diamondStorage();
		bool _isAffiliate = _appStorage.isAffiliate[_affiliateId];
		if (!_isAffiliate) {
			_appStorage.isAffiliate[_affiliateId] = true;
		}
	}

	/**
	 * @dev Mark an account as being an affiliate for a campaign.
	 * @param _account Ethereum address of the account.
	 * @param _campaignId Ethereum address of the campaign.
	 * @param _isAffiliate Affiliate status. If set to true, account will be set as an affiliate for given campaign.
	*/
	function _setIsAffiliate(
		address _account,
		address _campaignId,
		bool _isAffiliate
	) private {
		isCampaignAffiliate[_account][_campaignId] = _isAffiliate;
	}
}
