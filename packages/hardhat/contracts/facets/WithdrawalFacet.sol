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

/**
 * @title UNADUS: WithdrawalFacet
 * @author Danny Thomx
 * @notice This contract handles all withdrawal operations in the system.
 */
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

	/**
     * @notice Get the fee charged when there is a non member withdrawal.
     * @dev View function that is used to get the fee charge on non member withdrawals in basis points.
     * @return fee in basis points. 
     */
	function getWithdrawalFeeBasisPoints() public view returns (uint256 fee) {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		return fee = appStorage.withdrawalFee;
	}

	/**
     * @notice Check the cash out status of a token for a particular affiliate and campaign.
     * @dev View function to check if a given affiliate has already cashed out a token in a specific campaign.
     * @param _affiliateId Unique identifier(address) of the affiliate.
     * @param _tokenId Unique identifier of the token.
     * @param _campaignId Unique identifier(address) of the campaign.
     * @return isCashedOut Returns true if the token is already cashed out, otherwise false.
     */
	function getIsCashedOutToken(address _affiliateId, uint256 _tokenId, address _campaignId)external view returns(bool isCashedOut){
		isCashedOut = WithdrawalHelpers._isCashedOutToken(_affiliateId, _tokenId, _campaignId);
	}

	/**
     * @notice Get the total balance of fees in the specified token.
     * @dev View function that retrieves the balance of fees in the specified token.
     * @param _tokenAddress Address of the token.
     * @return Total balance of fees in the specified token.
     */
    function getFeesBalance(address _tokenAddress) external view returns(uint256) {
		AppStorage storage _appStorage = LibAppStorage.diamondStorage();
        bool isTokenRequest = _tokenAddress != address(0);
        return isTokenRequest ? _appStorage.feesTokenBalance[_tokenAddress] : _appStorage.feesEthBalance;
    }

	/**
     * @notice Get the withdrawable balance of an affiliate for a specific campaign.
     * @dev View function that gets the balance that an affiliate can currently withdraw from a specific campaign.
     * @param _campaignId Unique identifier(address) of the campaign.
     * @param _account Unique identifier(address) of the affiliate.
     * @param _tokenAddress Address of the token.
     * @return Withdrawable balance of the affiliate for the campaign in the specified token. 
     */
    function getAffiliateWithdrawableBalanceForCampaign(address _campaignId, address _account, address _tokenAddress) external view returns(uint256) {
		(uint256 withdrawableBalance,,) = WithdrawalHelpers._calculateAffiliateWithdrawableBalance(
			_account,
			_campaignId,
			_tokenAddress
		);
		return withdrawableBalance;
    }

	/**
     * @notice Get the balance of an affiliate that is currently available for a specific campaign. 
     * @dev View function that gets the balance of an affiliate that is currently available for withdrawal in a specific campaign.
     * @param _campaignId Unique identifier(address) of the campaign.
     * @param _account Unique identifier(address) of the affiliate.
     * @param _tokenAddress Address of the token (zero address for ETH).
     * @return  availableBalance balance of the affiliate that is currently available for withdrawal in the specific campaign and token. 
     */
	function getAffiliateAvailableBalanceForCampaign(address _campaignId, address _account, address _tokenAddress) external view returns(uint256 availableBalance) {
		availableBalance = WithdrawalHelpers._getAffiliateAvailableBalance(_campaignId, _account, _tokenAddress);   
	}

	/**
     * @notice Get the withdrawable balance of a campaign creator for a specific campaign.
     * @dev View function that retrieves the balance that a campaign creator can currently withdraw from a specific campaign.
     * @param _campaignId Unique identifier (address) of the campaign.
     * @param _tokenAddress Address of the token.
     * @return The withdrawable balance of the creator for the campaign in the specified token.
     */
	function getCreatorWithrawableBalanceForCampaign(address _campaignId, address _tokenAddress)external view returns(uint256){
		uint256 availableBalance = WithdrawalHelpers._fetchCreatorBalance(_campaignId, _tokenAddress);
        return availableBalance;
	}

	/**
     * @notice Set the percentage fee charged on withdrawals
     * @dev Only the contract owner can call this function
     * @param _feeBasisPoints The fee to be set, provided in basis points. For example, 100 for a 1% fee.
     */
	function setWithdrawalFee(
		uint256 _feeBasisPoints
	) external onlyOwner {
		AppStorage storage appStorage = LibAppStorage.diamondStorage();
		appStorage.withdrawalFee = _feeBasisPoints;
	}

 	/**
     * @notice Allows the contract owner to withdraw all accumulated Ether fees from the contract
     * @dev Can only be called by the owner of this contract.
     */
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

    /**
     * @notice Allows the contract owner to withdraw a specific amount of accumulated token fees from the contract.
     * @dev This function can only be called by the owner of this contract. Requires non-reentrant modifier to prevent re-entrancy attacks
     * @param _amount The amount of token fees to withdraw
     * @param _tokenAddress The address of the token
     */
    function withdrawTokenFees(uint256 _amount, address _tokenAddress) external 
        nonReentrant 
        onlySufficientTokenBalance(_amount, _tokenAddress) 
        onlyOwner 
    {
        _transferToken(_tokenAddress, _amount);
		_updateWithdrawalFeeBalance(_amount, false, _tokenAddress);
		emit FeesWithdrawal(_amount, msg.sender, _tokenAddress);
	}

    /**
     * @notice Allows a campaign creator to withdraw a specific amount of Ether from a specific campaign
     * @param _amount The amount of Ether to withdraw
     * @param _campaignId The address of the campaign
     */
    function creatorEthWithdrawal(	uint256 _amount, address _campaignId) external {
        _creatorWithdrawal(_amount, _campaignId, address(0));
		emit CreatorWithdrawal(_campaignId, _amount, msg.sender, address(0));
    }
    

    /**
     * @notice Allows a campaign creator to withdraw a specific amount of tokens from a specific campaign.
     * @param _amount The amount of tokens to withdraw
     * @param _campaignId The address of the campaign
     * @param _tokenAddress The address of the token
     */
    function creatorTokenWithdrawal(	uint256 _amount, address _campaignId, address _tokenAddress) external onlySufficientTokenBalance(_amount, _tokenAddress) {
        _creatorWithdrawal(_amount, _campaignId, _tokenAddress);
		emit CreatorWithdrawal(_campaignId, _amount, msg.sender, _tokenAddress);
    }

  	/**
     * @notice Allows an affiliate for a specific campaign to withdraw all accumulated Ethereum.
     * @dev This function allows an affiliate to call and withdraw their Ethereum per campaign.
     * @param _campaignId The address of the campaign.
     */
    function affiliateEthWithdrawal(address _campaignId) external {
       uint256 amount = _affiliateWithdrawal( _campaignId, address(0));
		emit AffiliateWithdrawal(_campaignId, amount, msg.sender, address(0));

    }

    /**
     * @notice Allows an affiliate for a specific campaign to withdraw all accumulated token.
     * @dev This function allows an affiliate to call and withdraw their token per campaign.
     * @param _campaignId The address of the campaign.
     * @param _tokenAddress The address of the token
     */
    function affiliateTokenWithdrawal(address _campaignId, address _tokenAddress) external {
       uint256 amount =  _affiliateWithdrawal(_campaignId, _tokenAddress);
		emit AffiliateWithdrawal(_campaignId, amount, msg.sender, _tokenAddress);
    }

	/**
     * @notice Calculate the withdrawal fee for a given amount.
     * @param _amount The amount to calculate the withdrawal fee upon.
     * @return withdrawalFee The calculated withdrawal fee.
     */
	function _calculateWithdrawalFee(
		uint256 _amount
	) internal view returns (uint256 withdrawalFee) {
		uint256 FEE_BASIS_POINTS = getWithdrawalFeeBasisPoints();
		withdrawalFee = (_amount * FEE_BASIS_POINTS) / 10000;
	}

    /**
     * @notice Method for the owner of a campaign to withdraw their balance.
     * @param _amount The amount the creator wishes to withdraw.
     * @param _campaignId The ID of the campaign the creator is withdrawing from.
     * @param _tokenAddress The address of the token.
     */
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

    /**
     * @notice Method for an affiliate to withdraw their earned funds.
     * @dev This method is only callable by the affiliate.
     * @param _campaignId The ID of the campaign.
     * @param _tokenAddress The address of the token.
     * @return withdrawalAmount The amount of tokens withdrawn by the affiliate.
     */
	function _affiliateWithdrawal(
		address _campaignId,
        address _tokenAddress
	) internal nonReentrant returns (uint256 withdrawalAmount){
		AffiliateInfo storage affiliate = AffiliateHelpers._getAffiliateData(
			_campaignId,
			msg.sender
		);
		// check affiliate exists
		require(
			affiliate.affiliateId != address(0),
			"Affiliate not found for Campaign Id"
		);
        bool isTokenWithdrawal = _tokenAddress != address(0);
        uint256 availableBalance = WithdrawalHelpers._getAffiliateAvailableBalance(_campaignId, msg.sender, _tokenAddress);
		// check affiliate has available balance
		require(
			availableBalance > 0,
			"Insufficient balance: Zero (0) Affiliate available balance"
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
		// check if withdrawable balance Validity
        require(
			availableBalance >= withdrawableBalance,
			"ERROR: Withdrawable balance > available balance"
		);
		// Check for membership and transfer funds if applicable
		if (Utilities._isMember(msg.sender)) {
			// Transfer funds to affiliate
		    isTokenWithdrawal ? _transferToken(_tokenAddress, withdrawableBalance) : _transferEth(payable(msg.sender), withdrawableBalance);

			// Deduct withdrawable balance from affiliate balance
			_deductBalance(_campaignId, withdrawableBalance, true, _tokenAddress);
			// Mark tokens as cashed out
			_markAsCashedOutTokens(
				msg.sender,
				_campaignId,
				directSalesTokenIds,
				refereesSalesTokenIds
			);
			// Exit after function execution
			return withdrawableBalance;
		}
		// For Non members
		// Calculate withdrawal fee
		uint256 withdrawalFee = _calculateWithdrawalFee(withdrawableBalance);
		// Deduct fee from withdrawable balance
		uint256 amountAfterFees = withdrawableBalance - withdrawalFee;
		// Send amountAfterFees to affiliate address
		isTokenWithdrawal ? _transferToken(_tokenAddress, amountAfterFees) : _transferEth(payable(msg.sender), amountAfterFees);
		// Update withdrawal fee balance
		_updateWithdrawalFeeBalance(withdrawalFee, true, _tokenAddress);
		// Deduct withdrawable balance from affiliate balance
		_deductBalance(_campaignId, withdrawableBalance, true, _tokenAddress);
		// Mark directSales and refereesSales tokenIds as cashed out
		_markAsCashedOutTokens(
			msg.sender,
			_campaignId,
			directSalesTokenIds,
			refereesSalesTokenIds
		);
		return amountAfterFees;
	}

    /**
     * @notice Update the withdrawal fee balance.
     * @param _amount The amount to update the balance with.
     * @param isDeposit Whether the action is a deposit or not.
     * @param _tokenAddress The address of the token.
     */
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

  	/**
     * @notice Deduct a specified amount from the balance.
     * @param _campaignId The ID of the campaign.
     * @param _withdrawalAmount The amount to withdraw.
     * @param _isAffiliate Whether the caller is an affiliate or not.
     * @param _tokenAddress The address of the token.
     */
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

 	/**
     * @notice Mark the given list of tokens as cashed out.
     * @param _affiliateId The ID of the affiliate.
     * @param _campaignId The ID of the campaign.
     * @param _directSalesTokenIds The IDs of the tokens sold directly.
     * @param _refereesSalesTokenIds The IDs of the tokens sold via referees.
     */
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

  	/**
     * @notice Tranfer a specified amount of Ether to a specified address.
     * @param _to The address to send the Ether to.
     * @param _amount The amount of Ether to send.
     */
    function _transferEth(address payable _to, uint256 _amount)private {
        (bool sent, ) = _to.call{ value: _amount }("");
		require(sent, "Failed to send Ether");
    }

 	/**
     * @notice Transfer a specified amount of a specified token to a specified address.
     * @param _tokenAddress The address of the token.
     * @param _amount The amount of the token to send.
     */
    function _transferToken(address _tokenAddress, uint256 _amount) private {
       bool sent = IERC20(_tokenAddress).transfer(msg.sender, _amount);
	   require(sent, "Failed to send Token");
    }
}
