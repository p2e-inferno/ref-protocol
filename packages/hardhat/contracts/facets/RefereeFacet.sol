// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// LibDiamond 💎 Allows For Diamond Storage
import "../libraries/LibDiamond.sol";

// LibRentalStorage 💎 Allows For Diamond Storage
import "../libraries/LibRefereeStorage.sol";

// LibAppStorage 📱 Allows For App Storage
import "../libraries/LibAppStorage.sol";

// Structs imported from AppStorage
import "../libraries/LibCampaignStorage.sol";

// Hardhat Console Debugging Easy
import "hardhat/console.sol";


// @title UNADUS 
/// @author Danny Thomx
/// @notice
/// @dev
contract RefereeFacet is ReentrancyGuard{
    // Using App Storage
    AppStorage internal appStorage;
    // RefereeStorage internal refereeStorage;


    /// @notice This view function returns the rental status of NFT using tokenID
    /// @dev The tokenID is used to fetch rental details of the NFT from Diamond Storage
    /// @param _referee The tokenID of the NFT to fetch rental status
    /// @return This function returns Rental Information of NFT using Diamond Storage
    function referralOf(address _referee) external view returns (address) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.referrerOf[_referee];
    }

    /// @notice This function returns the rental status of NFT using tokenID
    /// @dev The tokenID is used to fetch rental details of the NFT from Diamond Storage
    /// @param _referee The tokenID of the NFT to fetch rental status
    /// @param _affiliate The tokenID of the NFT to fetch rental status
    function _setReferrer(address _referee, address _affiliate) private {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      _storage.referrerOf[_referee] = _affiliate;
    }

    /// @notice This view function returns all NFTs listed in rental marketplace
    /// @dev The function loops through all the NFTs the contract owns and checks the rental status using Diamond Storage
    /// @return This function returns 3 arrays -> first array contains the Chararacter Attributes of NFTs; second array contains the Rental Information of NFTs; third array contains the tokenIDs of NFTs
     function getRefereeInfo(address _referee) external view returns (RefereeInfo memory) {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      return _storage.refereeData[_referee];
    }

    /// @notice This view function returns NFTs that a user has listed in rental marketplace
    /// @dev The function returns NFTs that are listed by the user through the rental marketplace; This function returns both the lent nfts & listed nfts

    function _setRefereeData(address _campaignId, address _referee, address _referrer, uint256 _tokenId ) private {
      RefereeStorage storage _storage = LibRefereeStorage.diamondStorage();
      RefereeInfo memory info;
      info.campaignId = _campaignId;
      info.id = _referee;
      info.referrer = _referrer;
      info.keyPurchased = _tokenId;
      _storage.refereeData[_referee] = info;
    }

    /// @notice This view function returns only NFTs that a user owns, and has not listed in marketplace
    /// @dev The function returns only NFTs that are owned by user but are not listed in the rental marketplace
    /// @return This function returns 3 arrays -> first array contains the Chararacter Attributes of NFTs; second array contains the Rental Information of NFTs; third array contains the tokenIDs of NFTs
    // function fetchMyUnListedNFTs() external view returns(CharacterAttributes[] memory, uint[] memory){

    //     uint[] memory nftArray = LibERC721._tokensOfOwner(msg.sender);
    //     uint itemCount = 0;
    //     uint currentIndex = 0;

    //     if(nftArray.length == 0){
    //         CharacterAttributes[] memory emptyStruct;
    //         uint[] memory emptyArray;
    //         return (emptyStruct, emptyArray);
    //     }

    //     LibRentalStorage.RentalMarketData storage rss = LibRentalStorage.diamondStorage();

    //     for (uint i; i < nftArray.length; i++) {
    //         if ( (rss.Rental[nftArray[i]].seller != msg.sender) && (rss.Rental[nftArray[i]].isRented == false) ) {
    //             itemCount += 1;
    //         }
    //     }

    //     if(itemCount == 0){
    //         CharacterAttributes[] memory emptyStruct;
    //         uint[] memory emptyArray;
    //         return (emptyStruct, emptyArray);
    //     }

    //     CharacterAttributes[] memory charArray = new CharacterAttributes[](itemCount);
    //     uint[] memory tokenArray = new uint[](itemCount);


    //     for (uint i; i < nftArray.length; i++) {

    //         if ( (rss.Rental[nftArray[i]].seller != msg.sender) && (rss.Rental[nftArray[i]].isRented == false) ) {

    //             charArray[currentIndex] = s.nftHolderAttributes[nftArray[i]];
    //             tokenArray[currentIndex] = nftArray[i];
    //             currentIndex += 1;
    //         }
    //     }

    //     return (charArray, tokenArray);

    // }

    /// @notice This view function returns only NFTs that a user has rented from marketplace
    /// @dev The function loops through NFTs that are owned by user, and returns only NFTs that are rented by the user
    /// @return This function returns 3 arrays -> first array contains the Chararacter Attributes of NFTs; second array contains the Rental Information of NFTs; third array contains the tokenIDs of NFTs
    // function fetchRentedNFTs() external view returns(CharacterAttributes[] memory, LibRentalStorage.RentalInfo[] memory, uint[] memory){

    //     uint[] memory nftArray = LibERC721._tokensOfOwner(msg.sender);
    //     uint itemCount = 0;
    //     uint currentIndex = 0;

    //     if(nftArray.length == 0){
    //         CharacterAttributes[] memory emptyStruct;
    //         LibRentalStorage.RentalInfo[] memory emptyItems;
    //         uint[] memory emptyArray;
    //         return (emptyStruct, emptyItems, emptyArray);
    //     }

    //     LibRentalStorage.RentalMarketData storage rss = LibRentalStorage.diamondStorage();

    //     for (uint i; i < nftArray.length; i++) {
    //         if (rss.Rental[nftArray[i]].renter == msg.sender) {
    //             itemCount += 1;
    //         }
    //     }

    //     if(itemCount == 0){
    //         CharacterAttributes[] memory emptyStruct;
    //         LibRentalStorage.RentalInfo[] memory emptyItems;
    //         uint[] memory emptyArray;
    //         return (emptyStruct, emptyItems, emptyArray);
    //     }

    //     CharacterAttributes[] memory charArray = new CharacterAttributes[](itemCount);
    //     LibRentalStorage.RentalInfo[] memory marketItems = new LibRentalStorage.RentalInfo[](itemCount);
    //     uint[] memory tokenArray = new uint[](itemCount);


    //     for (uint i; i < nftArray.length; i++) {

    //         if (rss.Rental[nftArray[i]].renter == msg.sender) { 

    //             charArray[currentIndex] = s.nftHolderAttributes[nftArray[i]];
    //             marketItems[currentIndex] = rss.Rental[nftArray[i]];
    //             tokenArray[currentIndex] = nftArray[i];
    //             currentIndex += 1;
    //         }
    //     }

    //     return (charArray, marketItems, tokenArray);

    // }
    

    /// @notice This view function returns only NFTs that are lent by the user
    /// @dev The function loops through NFTs that are owned by user, and returns only NFTs that are rented by the user
    /// @return This function returns 3 arrays -> first array contains the Chararacter Attributes of NFTs; second array contains the Rental Information of NFTs; third array contains the tokenIDs of NFTs
    // function fetchLentNFTs() external view returns(CharacterAttributes[] memory, LibRentalStorage.RentalInfo[] memory, uint[] memory){

    //     uint totalItemCount = s.totalTokens;
    //     uint itemCount = 0;
    //     uint currentIndex = 0;
    //     LibRentalStorage.RentalMarketData storage rss = LibRentalStorage.diamondStorage();
        

    //     for (uint i = 0; i < totalItemCount; i++) {
    //         if ((rss.Rental[i + 1].seller == msg.sender) && (rss.Rental[i + 1].isRented == true)) {
    //             itemCount += 1;
    //         }
    //     }

    //     if(itemCount == 0){
    //         CharacterAttributes[] memory emptyStruct;
    //         LibRentalStorage.RentalInfo[] memory emptyItems;
    //         uint[] memory emptyArray;
    //         return (emptyStruct, emptyItems, emptyArray);
    //     }

    //     CharacterAttributes[] memory charArray = new CharacterAttributes[](itemCount);
    //     LibRentalStorage.RentalInfo[] memory marketItems = new LibRentalStorage.RentalInfo[](itemCount);
    //     uint[] memory tokenArray = new uint[](itemCount);

    //     for (uint i = 0; i < totalItemCount; i++) {

    //         if ((rss.Rental[i + 1].seller == msg.sender) && (rss.Rental[i + 1].isRented == true)) {

    //             charArray[currentIndex] = s.nftHolderAttributes[i+1];
    //             marketItems[currentIndex] = rss.Rental[i + 1];
    //             tokenArray[currentIndex] = i+1;
    //             currentIndex += 1;
                
    //         }
    //     }

    //     return (charArray, marketItems, tokenArray);


    // }
    

}