// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/ikollect-1155-v1.sol";

contract KollectPrivateCollection_V1 is 
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    UUPSUpgradeable
{
    
    struct CollectionItem {
        uint256 item_id;
        uint256 item_count;
    }

    mapping (address => mapping(uint256 => CollectionItem[])) private collections;
    mapping (address => bool) whitelistedContracts;

    event ItemAddedToCollection(address tokenAddress, uint256 tokenId, uint256 amount, uint256 collectionId, address ownerAddress);
    event ItemRemovedFromCollection(address tokenAddress, uint256 tokenId, uint256 amount, uint256 collectionId, address ownerAddress);
    event AddedContractToWhitelists(address contractAddress);
    
    function initialize(address _nftAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        addContractAddress(_nftAddress);
    }

    function addContractAddress(address _contract) public onlyOwner {
        whitelistedContracts[_contract] = true;
        emit AddedContractToWhitelists(_contract);
    }

    modifier isValidContractAddress(address _contract) {
        require(whitelistedContracts[_contract], "not valid contract");
        _;
    }

    function checkCollectionItem(CollectionItem[] storage collectionArray, uint tokenId, uint tokenAmount) internal returns (bool) {
        if (collectionArray.length == 0) return false;
        for (uint i = 0; i < collectionArray.length; i++)
        {
            if (collectionArray[i].item_id == tokenId) {
                collectionArray[i].item_count += tokenAmount;
                return true;
            }
        }
        return false;
    }

    function findCollectionItem(CollectionItem[] memory collectionArray, uint tokenId) internal pure returns (uint) {
        if (collectionArray.length == 0) return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        for (uint i = 0; i < collectionArray.length; i++)
        {
            if (collectionArray[i].item_id == tokenId) {
                return i;
            }
        }
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function addItemToCollection(address contractAddress, uint256 tokenId, uint256 tokenAmount, uint256 collectionId) public {
        require(whitelistedContracts[contractAddress], "not valid contract");
        IKOLLECT1155_V1 kollect_nft = IKOLLECT1155_V1(contractAddress);
        require(kollect_nft.balanceOf(_msgSender(), tokenId) > 0, "caller must own given token");
        require(kollect_nft.balanceOf(_msgSender(), tokenId) >= tokenAmount, "caller must have enough amounts");
        require(kollect_nft.isApprovedForAll(_msgSender(), address(this)), "contract must be approved");
        
        kollect_nft.safeTransferFrom(_msgSender(), address(this), tokenId, tokenAmount, "");

        bool check = checkCollectionItem(collections[_msgSender()][collectionId], tokenId, tokenAmount);
        if (!check) {
            collections[_msgSender()][collectionId].push(CollectionItem({
                item_id: tokenId,
                item_count: tokenAmount
            }));
        }
        
        emit ItemAddedToCollection(contractAddress, tokenId, tokenAmount, collectionId, _msgSender());
    }

    function removeItemFromCollection(address contractAddress, uint256 tokenId, uint256 tokenAmount, uint256 collectionId) public {
        require(whitelistedContracts[contractAddress], "not valid contract");
        IKOLLECT1155_V1 kollect_nft = IKOLLECT1155_V1(contractAddress);
        require(collections[_msgSender()][collectionId].length > 0, "not existed collection");
        
        uint index = findCollectionItem(collections[_msgSender()][collectionId], tokenId);
        if (index != 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            require(collections[_msgSender()][collectionId][index].item_id == tokenId, "not existed the token in collection");
            require(collections[_msgSender()][collectionId][index].item_count >= tokenAmount, "not enough token in collection to withdraw");
            
            collections[_msgSender()][collectionId][index].item_count -= tokenAmount;
            kollect_nft.safeTransferFrom(address(this), _msgSender(), tokenId, tokenAmount, "");
        }
        
        emit ItemRemovedFromCollection(contractAddress, tokenId, tokenAmount, collectionId, _msgSender());
    }

    function getCollection(address account, uint256 collectionId) public view returns (CollectionItem[] memory) {
        return collections[account][collectionId];
    }

    function getCollectionArrays(address account, uint256 collectionId) public view returns (uint[] memory, uint[] memory) {
        
        uint[] memory ids = new uint[](collections[account][collectionId].length);
        uint[] memory counts = new uint[](collections[account][collectionId].length);

        for (uint i = 0; i < collections[account][collectionId].length; i++) {
            ids[i] = collections[account][collectionId][i].item_id;
            counts[i] = collections[account][collectionId][i].item_count;
        }
        return (ids, counts);
    }

    function getMyCollection(uint256 collectionId) public view returns (CollectionItem[] memory) {
        return collections[_msgSender()][collectionId];
    }

    function getMyCollectionArrays(uint256 collectionId) public view returns (uint[] memory, uint[] memory) {
        
        uint[] memory ids = new uint[](collections[_msgSender()][collectionId].length);
        uint[] memory counts = new uint[](collections[_msgSender()][collectionId].length);

        for (uint i = 0; i < collections[_msgSender()][collectionId].length; i++) {
            ids[i] = collections[_msgSender()][collectionId][i].item_id;
            counts[i] = collections[_msgSender()][collectionId][i].item_count;
        }
        return (ids, counts);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}