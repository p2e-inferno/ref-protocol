// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../libraries/storage/LibRefereeStorage.sol";
import "../libraries/storage/LibAffiliateStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import "../libraries/storage/LibAppStorage.sol";

// @title UNADUS
/// @author Dannt Thomx
/// @notice
/// @dev
contract AffiliateFacet {
	mapping(address => mapping(address => bool)) isCampaignAffiliate;
	event NewAffiliate(address indexed affiliate, address campaignId);

	function getCampaingAffiliates(address _campaignId) external view returns (address[] memory campaignAffiliates) {
		AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
		campaignAffiliates = affiliateStorage.affiliatesOf[_campaignId];
	}

	function getRefereesOf(
		address _affiliate,
		address _campaignId
	) external view returns (address[] memory) {
		AffiliateStorage storage _storage = LibAffiliateStorage
			.diamondStorage();
		return _storage.refereesOf[_affiliate][_campaignId];
	}

	function getCampaignAffiliatesCount(address _campaignId)external view returns(uint256 count) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
	    count =  _storage.affiliatesOf[_campaignId].length;
	}

	function getIsCampaignAffiliate(
		address _affiliate,
		address _campaignId
	) external view returns (bool) {
		return isCampaignAffiliate[_affiliate][_campaignId];
	}

	function getAffiliateReferrer(address _affiliateId, address _campaignId) external view returns(address referrer) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        referrer = _storage.affiliateData[_affiliateId][_campaignId].referrer;
	}

	function getAffiliateEthBalanceForCampaign(address _affiliateId, address _campaignId)view external returns (uint256 balance) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
		balance = _storage.affiliateBalance[_affiliateId].etherBalance[_campaignId];
	}

	function getAffiliateTokenBalanceForCampaign(address _affiliateId, address _campaignId, address _tokenAddress) view external returns (uint256 balance) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
 		balance = _storage.affiliateBalance[_affiliateId].tokenBalance[_campaignId][_tokenAddress];
	}

	function getAffiliateSoldTokens(address _affiliateId, address _campaignId) external view returns(uint256[] memory soldTokens) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        soldTokens = _storage.affiliateData[_affiliateId][_campaignId].soldTokens;
	}

	function getAffiliateDownlineSoldTokens(address _affiliateId, address _campaignId) external view returns(uint256[] memory soldTokens) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        soldTokens = _storage.affiliateData[_affiliateId][_campaignId].refereesSoldTokens;
	}

	function getAffiliateSaleData(address _affiliateId, address _campaignId, uint256 _tokenId) external view returns(SaleInfo memory saleInfo) {
	    AffiliateStorage storage _storage = LibAffiliateStorage.diamondStorage();
        saleInfo = _storage.affiliateData[_affiliateId][_campaignId].saleData[_tokenId];
	}

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

	function _setIsAffiliate(
		address _account,
		address _campaignId,
		bool _isAffiliate
	) private {
		isCampaignAffiliate[_account][_campaignId] = _isAffiliate;
	}
}
