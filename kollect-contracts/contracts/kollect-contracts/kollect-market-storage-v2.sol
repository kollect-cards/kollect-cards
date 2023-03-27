// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract KollectMarketStorage_V2 is 
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct SimpleMarket {
        uint256 index;
        address addressNFTCollection;
        address addressPaymentToken;
        uint256 nftId;
        uint256 nftCount;
        address payable creator;
        address payable currentBuyer;
        uint256 currentListingPrice;
        bool isSold;
        bool canClaim;
    }

    event NewSimpleMarket(
        uint256 index,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        uint256 nftCount,
        address mintedBy,
        address currentBuyer,
        uint256 currentListingPrice,
        bool isSold,
        bool canClaim
    );
    
    string public name;
    
    uint public listingFeeRate;
    address payable operator;

    uint256 public simpleMarketIndex;
    uint256 public simpleMarketSoldIndex;

    SimpleMarket[] internal allSimpleMarkets;
    mapping (address => bool) whitelistedContracts;

    string public version;
    
    function initialize() public initializer {
    }

        function addContractAddress(address _contract) public onlyOwner {
        whitelistedContracts[_contract] = true;
    }

    modifier isValidContractAddress(address _contract) {
        require(whitelistedContracts[_contract], "not valid contract");
        _;
    }

    modifier isValidFetchRequest(uint _itemsPerPage, uint _pageNum) {
        uint unboundedLimit = 256;
        uint from = _itemsPerPage * _pageNum - _itemsPerPage;
        uint to = simpleMarketIndex;
        require(_itemsPerPage > 0 && _pageNum > 0, "fetch params are invalid");
        require(to - from <= unboundedLimit, "fetch size is to big");
        require(from < simpleMarketIndex, "fetch position is invalid");
        _;
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function changeOperator(address _addr) public onlyOwner returns (bool) {
        operator = payable(_addr);
        return true;
    }

    function changeListingFeeRate(uint _rate) public onlyOwner returns (bool) {
        require(_rate <= 10000, "Rate can't exceed 100%");

        listingFeeRate = _rate;
        return true;
    }

    function getMarketName() public view returns (string memory) {
        return name;
    }

    function setVersion(string calldata version_) public onlyOwner {
        version = version_;
    }

    function getVersion() public view returns (string memory) {
        return version;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}