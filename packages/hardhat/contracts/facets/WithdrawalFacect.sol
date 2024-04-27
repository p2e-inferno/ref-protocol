// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/storage/LibAppStorage.sol";
import "../libraries/storage/LibCampaignStorage.sol";
import "../libraries/Utilities.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { AffiliateHelpers } from "../libraries/helpers/AffiliateHelpers.sol";
import { CampaignHelpers } from "../libraries/helpers/CampaignHelpers.sol";
import { WithdrawalHelpers } from "../libraries/helpers/WithdrawalHelpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @title UNADUS: WithdrawalFacet
/// @author Danny Thomx
/// @notice
/// @dev

contract WithdrawalFacet is Modifiers, ReentrancyGuard {

	event AffiliateWithdrawal(
		address indexed campaignId,
		uint256 indexed _amount,
		address _recipient,
		address _tokenAddress
	);

	event FeesWithdrawal(
		uint256 indexed _amount,
		address _recipient,
		address _tokenAddress
	);

	event CreatorWithdrawal(
		address indexed campaignId,
		uint256 indexed _amount,
		address _recipient,
		address _tokenAddress
	);

	function getPercentageWithdrawalFee() public view returns (uint256 fee) {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		return fee = appStorage.withdrawalFee;
	}

    function getFeesBalance(address _tokenAddress) external view returns(uint256) {
		AppStorage storage _appStorage = LibAppStorage.diamondStorage();
        bool isTokenRequest = _tokenAddress != address(0);
        return isTokenRequest ? _appStorage.feesTokenBalance[_tokenAddress] : _appStorage.feesEthBalance;
    }

    function getAffiliateWithdrawableBalanceForCampaign(address _campaignId, address _account, address _tokenAddress) external view returns(uint256) {
		(uint256 withdrawableBalance,,) = WithdrawalHelpers._calculateAffiliateWithdrawableBalance(
			_account,
			_campaignId,
			_tokenAddress
		);
		return withdrawableBalance;
    }

	function getCreatorWithrawableBalanceForCampaign(address _campaignId, address _tokenAddress)external view returns(uint256){
		uint256 availableBalance = WithdrawalHelpers._fetchCreatorBalance(_campaignId, _tokenAddress);
        return availableBalance;
	}

	function setPercentageWithdrawalFee(
		uint256 _feePercentage
	) external onlyOwner {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		appStorage.withdrawalFee = _feePercentage;
	}

	function withdrawEthFees() external 
        nonReentrant 
        onlyOwner 
    {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		uint256 amount = appStorage.feesEthBalance;
		require(amount > 0, "Zero Fees balance");
		// Send amount to owner address
		_transferEth(payable(msg.sender), amount);
		// Deduct amount from fees balance
		_updateWithdrawalFeeBalance(amount, false, address(0));
		emit FeesWithdrawal(amount, msg.sender, address(0));
	}

    function withdrawTokenFees(uint256 _amount, address _tokenAddress) external 
        nonReentrant 
        onlySufficientTokenBalance(_amount, _tokenAddress) 
        onlyOwner 
    {
        _transferToken(_tokenAddress, _amount);
		_updateWithdrawalFeeBalance(_amount, false, _tokenAddress);
		emit FeesWithdrawal(_amount, msg.sender, _tokenAddress);
	}

    function creatorEthWithdrawal(	uint256 _amount, address _campaignId) external {
        _creatorWithdrawal(_amount, _campaignId, address(0));
		emit CreatorWithdrawal(_campaignId, _amount, msg.sender, address(0));
    }
    
    function creatorTokenWithdrawal(	uint256 _amount, address _campaignId, address _tokenAddress) external onlySufficientTokenBalance(_amount, _tokenAddress) {
        _creatorWithdrawal(_amount, _campaignId, _tokenAddress);
		emit CreatorWithdrawal(_campaignId, _amount, msg.sender, _tokenAddress);
    }

    function affiliateEthWithdrawal(uint256 _amount, address _campaignId) external {
        _affiliateWithdrawal(_amount, _campaignId, address(0));
		emit AffiliateWithdrawal(_campaignId, _amount, msg.sender, address(0));

    }

    function affiliateTokenWithdrawal(uint256 _amount, address _campaignId, address _tokenAddress) external onlySufficientTokenBalance(_amount, _tokenAddress) {
        _affiliateWithdrawal(_amount, _campaignId, _tokenAddress);
		emit AffiliateWithdrawal(_campaignId, _amount, msg.sender, _tokenAddress);
    }

	function _calculateWithdrawalFee(
		uint256 _amount
	) internal view returns (uint256 withdrawalFee) {
		uint256 FEE_PERCENTAGE = getPercentageWithdrawalFee();
		withdrawalFee = (_amount * FEE_PERCENTAGE) / 100;
	}

	function _creatorWithdrawal(
		uint256 _amount,
		address _campaignId,
        address _tokenAddress
	)
		internal
		nonReentrant
		onlyCampaignOwner(_campaignId)
	{
		// Fetch available balance and check if it's sufficient
		uint256 availableBalance = WithdrawalHelpers._fetchCreatorBalance(_campaignId, _tokenAddress);
		require(
			_amount <= availableBalance,
			"Insufficient balance: Withdrawable balance less than amount"
		);
        bool isTokenWithdrawal = _tokenAddress != address(0);

		// Check for membership and transfer funds
		if (Utilities._isMember(msg.sender)) {
			// Transfer funds to creator
			isTokenWithdrawal ? _transferToken(_tokenAddress, _amount) : _transferEth(payable(msg.sender), _amount);

			// Deduct availableBalance from creator balance
			_deductBalance(_campaignId, _amount, false, _tokenAddress);
			// Exit function execution
			return;
		}
		// Calculate withdrawal fee
		uint256 withdrawalFee = _calculateWithdrawalFee(_amount);
		require(_amount >= withdrawalFee, "Balance less than withdrawal fees");
		// Deduct fee from withdrawable balance
		uint256 amountAfterFees = _amount - withdrawalFee;
		// Send amountAfterFees to creator address
		isTokenWithdrawal ? _transferToken(_tokenAddress, amountAfterFees) : _transferEth(payable(msg.sender), amountAfterFees);
		// Deduct availableBalance from creator balance
		_deductBalance(_campaignId, _amount, false, _tokenAddress);
		// Update withdrawal fee balance
		_updateWithdrawalFeeBalance(withdrawalFee, true, _tokenAddress);
	}

	function _affiliateWithdrawal(
		uint256 _amount,
		address _campaignId,
        address _tokenAddress
	) internal nonReentrant {
		AffiliateInfo storage affiliate = AffiliateHelpers._getAffiliateData(
			_campaignId,
			msg.sender
		);
        AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
		// check affiliate exists
		require(
			affiliate.affiliateId != address(0),
			"Affiliate not found for Campaign Id"
		);
        bool isTokenWithdrawal = _tokenAddress != address(0);
        uint256 availableBalance = isTokenWithdrawal ? affiliateStorage.affiliateBalance[msg.sender].tokenBalance[_campaignId][_tokenAddress] : affiliateStorage.affiliateBalance[msg.sender].etherBalance[_campaignId];
		// check affiliate has enough balance
		require(
			availableBalance>= _amount,
			"Insufficient balance: Affiliate total balance less than amount"
		);
		// Calculate withdrawable balance
		(
			uint256 withdrawableBalance,
			uint256[] memory directSalesTokenIds,
			uint256[] memory refereesSalesTokenIds
		) = WithdrawalHelpers._calculateAffiliateWithdrawableBalance(
				msg.sender,
				_campaignId,
                _tokenAddress
			);
		// check if withdrawable balance is sufficient
        require(
			_amount <= withdrawableBalance,
			"Insufficient balance: Withdrawable balance less than amount"
		);
		// Check for membership and transfer funds if applicable
		if (Utilities._isMember(msg.sender)) {
			// Transfer funds to affiliate
		    isTokenWithdrawal ? _transferToken(_tokenAddress, _amount) : _transferEth(payable(msg.sender), _amount);

			// Deduct withdrawable balance from affiliate balance
			_deductBalance(_campaignId, _amount, true, _tokenAddress);
			// Mark tokens as cashed out
			_markAsCashedOutTokens(
				msg.sender,
				_campaignId,
				directSalesTokenIds,
				refereesSalesTokenIds
			);
			// Exit after function execution
			return;
		}
		// Calculate withdrawal fee
		uint256 withdrawalFee = _calculateWithdrawalFee(withdrawableBalance);
		// Deduct fee from withdrawable balance
		uint256 amountAfterFees = _amount - withdrawalFee;
		// Send amountAfterFees to affiliate address
		isTokenWithdrawal ? _transferToken(_tokenAddress, amountAfterFees) : _transferEth(payable(msg.sender), amountAfterFees);
		// Update withdrawal fee balance
		_updateWithdrawalFeeBalance(withdrawalFee, true, _tokenAddress);
		// Deduct withdrawable balance from affiliate balance
		_deductBalance(_campaignId, _amount, true, _tokenAddress);
		// Mark directSales and refereesSales tokenIds as cashed out
		_markAsCashedOutTokens(
			msg.sender,
			_campaignId,
			directSalesTokenIds,
			refereesSalesTokenIds
		);
	}

	function _updateWithdrawalFeeBalance(
		uint256 _amount,
		bool isDeposit, 
        address _tokenAddress
	) private {
		AppStorage storage _appStorage = LibAppStorage.diamondStorage();
        bool isTokenRequest = _tokenAddress != address(0);
		if(isDeposit) {
			isTokenRequest ? _appStorage.feesTokenBalance[_tokenAddress] += _amount : _appStorage.feesEthBalance += _amount;
        } else{
			isTokenRequest ? _appStorage.feesTokenBalance[_tokenAddress] -= _amount : _appStorage.feesEthBalance -= _amount;
        }
	}

	function _deductBalance(
		address _campaignId,
		uint256 _withdrawalAmount,
		bool _isAffiliate,
        address _tokenAddress
	) private {
        AffiliateStorage storage affiliateStorage = LibAffiliateStorage.diamondStorage();
        CampaignStorage storage campaignStorage = LibCampaignStorage.diamondStorage();
        bool isTokenWithdrawal = _tokenAddress != address(0);
		// check if creator/ Affiliate
		if (!_isAffiliate) {
		  // If user is a creator (i.e not an affiliate) deduct withdrawal amount from nonCommissionBalance for the campaign
		  isTokenWithdrawal ?  campaignStorage.nonCommissionTokenBalance[_campaignId][_tokenAddress]  -= _withdrawalAmount : campaignStorage.nonCommissionEtherBalance[_campaignId] -= _withdrawalAmount;
		  return;
		}
		// deduct withdrawal amount from affiliateBalance
		isTokenWithdrawal ? affiliateStorage.affiliateBalance[msg.sender].tokenBalance[_campaignId][_tokenAddress] -= _withdrawalAmount : affiliateStorage.affiliateBalance[msg.sender].etherBalance[_campaignId] -= _withdrawalAmount;
		// deduct withdrawal amount from commissionBalance for campaign
		isTokenWithdrawal ?  campaignStorage.commissionTokenBalance[_campaignId][_tokenAddress]  -= _withdrawalAmount :	campaignStorage.commissionEtherBalance[_campaignId] -= _withdrawalAmount;
	}

	function _markAsCashedOutTokens(
		address _affiliateId,
		address _campaignId,
		uint[] memory _directSalesTokenIds,
		uint[] memory _refereesSalesTokenIds
	) private {
		CampaignStorage storage campaignStorage = LibCampaignStorage
			.diamondStorage();

		for (uint i = 0; i < _directSalesTokenIds.length; i++) {
			campaignStorage.cashedOutTokens[_campaignId].isCashedOutToken[_affiliateId][
				_directSalesTokenIds[i]
			] = true;
		}

		for (uint j = 0; j < _refereesSalesTokenIds.length; j++) {
			campaignStorage.cashedOutTokens[_campaignId].isCashedOutToken[_affiliateId][
				_refereesSalesTokenIds[j]
			] = true;
		}
	}

    function _transferEth(address payable _to, uint256 _amount)private {
        (bool sent, ) = _to.call{ value: _amount }("");
		require(sent, "Failed to send Ether");
    }

    function _transferToken(address _tokenAddress, uint256 _amount) private {
       bool sent = IERC20(_tokenAddress).transfer(msg.sender, _amount);
	   require(sent, "Failed to send Token");
    }
}
