// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./kollect-market-storage-v1.sol";
import "./interfaces/ikollect-1155-v1.sol";

contract KollectMarketLogic_V1 is 
    KollectMarketStorage_V1
{
    event ItemPurchasedOnSimpleMarket(uint256 salesIndex, uint256 price);
    event NFTClaimedFromSimpleMarket(uint256 salesIndex, uint256 nftId, uint256 nftCount, address claimedBy);
    event CanceledNFTClaimedFromSimpleMarket(uint256 salesIndex, uint256 nftId, uint256 nftCount, address claimedBy);
    event TokensClaimedFromSimpleMarket(uint256 salesIndex, uint256 nftId, uint256 nftCount, address claimedBy);
    event NFTRefundedFromSimpleMarket(uint256 salesIndex, uint256 nftId, uint256 nftCount, address claimedBy);

    function initialize(string memory _name, address _nftAddress, address _kolAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        name = _name;
        operator = payable(_msgSender());
        addContractAddress(_nftAddress);
        addContractAddress(_kolAddress);

        listingFeeRate = 500; // 500 / 10000 = 5%
        simpleMarketIndex = 0;
        simpleMarketSoldIndex = 0;
    }

    /**
     * Create a new market of a specific NFT
     * @param _addressNFTCollection address of the ERC1155 NFT collection contract
     * @param _addressPaymentToken address of the payment token contract
     * @param _nftId Id of the NFT for sale
     * @param _nftCount quantity of the NFT for sale
     * @param _initialPrice Inital price by the creator of the market
     */
    function createSimpleMarketSale(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _nftCount,
        uint256 _initialPrice
    ) external returns (uint256) {
        require(whitelistedContracts[_addressNFTCollection], "not valid NFT contract");
        require(whitelistedContracts[_addressPaymentToken], "not valid Token contract");

        // Check if the initial price is > 0
        require(_initialPrice > 0, "Invalid initial price");

        // Get NFT collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(_addressNFTCollection);

        // Make sure the sender has enough NFT quantities
        require(nftCollection.balanceOf(_msgSender(), _nftId) >= _nftCount, "Caller has not enough NFT");

        // Make sure the owner of the NFT approved that the Market contract is allowed to change ownership of the NFT
        require(nftCollection.isApprovedForAll(_msgSender(), address(this)), "Require NFT ownership transfer approval");

        // Lock NFT in Market contract
        nftCollection.safeTransferFrom(_msgSender(), address(this), _nftId, _nftCount, "");

        // Casting from address to address payable
        address payable currentBuyer = payable(address(0));

        // Create new Market object
        SimpleMarket memory newMarket = SimpleMarket({
            index: simpleMarketIndex,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            nftCount: _nftCount,
            creator: payable(_msgSender()),
            currentBuyer: currentBuyer,
            currentListingPrice: _initialPrice,
            isSold: false,
            canClaim: true
        });

        // Update list
        allSimpleMarkets.push(newMarket);

        // Trigger event and return index of new market
        emit NewSimpleMarket(
            simpleMarketIndex,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            _nftCount,
            _msgSender(),
            currentBuyer,
            _initialPrice,
            false,
            true
        );

        // Increment market sequence
        simpleMarketIndex++;
        
        return simpleMarketIndex;
    }

    /**
     * Create a new market of a specific NFT payment by Base Asset - Matic(Polygon)
     * @param _addressNFTCollection address of the ERC1155 NFT collection contract
     * @param _nftId Id of the NFT for sale
     * @param _nftCount quantity of the NFT for sale
     * @param _initialPrice Inital price by the creator of the market
     */
    function createSimpleMarketSaleForBaseAsset(
        address _addressNFTCollection,
        uint256 _nftId,
        uint256 _nftCount,
        uint256 _initialPrice
    ) external returns (uint256) {
        require(whitelistedContracts[_addressNFTCollection], "not valid NFT contract");
        
        // Check if the initial price is > 0
        require(_initialPrice > 0, "Invalid initial price");

        // Get NFT collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(_addressNFTCollection);

        // Make sure the sender has enough NFT quantities
        require(nftCollection.balanceOf(_msgSender(), _nftId) >= _nftCount, "Seller has not enough NFT");

        // Make sure the owner of the NFT approved that the Market contract is allowed to change ownership of the NFT
        require(nftCollection.isApprovedForAll(_msgSender(), address(this)), "Require NFT ownership transfer approval");

        // Lock NFT in Market contract
        nftCollection.safeTransferFrom(_msgSender(), address(this), _nftId, _nftCount, "");

        // Casting from address to address payable
        address payable currentBuyer = payable(address(0));

        // Create new Market object
        SimpleMarket memory newMarket = SimpleMarket({
            index: simpleMarketIndex,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: address(0x0),
            nftId: _nftId,
            nftCount: _nftCount,
            creator: payable(_msgSender()),
            currentBuyer: currentBuyer,
            currentListingPrice: _initialPrice,
            isSold: false,
            canClaim: true
        });

        // Update list
        allSimpleMarkets.push(newMarket);

        // Trigger event and return index of new Market
        emit NewSimpleMarket(
            simpleMarketIndex,
            _addressNFTCollection,
            address(0x0),
            _nftId,
            _nftCount,
            _msgSender(),
            currentBuyer,
            _initialPrice,
            false,
            true
        );

        // Increment market sequence
        simpleMarketIndex++;

        return simpleMarketIndex;
    }

    function isSold(uint256 _marketIndex) public view returns (bool) {
        require(_marketIndex < allSimpleMarkets.length, "out of bound");
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];
        return market.isSold;
    }

    function canClaim(uint256 _marketIndex) public view returns (bool) {
        require(_marketIndex < allSimpleMarkets.length, "out of bound");
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];
        return market.canClaim;
    }

    function getMarketItem(uint256 _marketIndex) public view returns (SimpleMarket memory) {
        require(_marketIndex < allSimpleMarkets.length, "out of bound");
        SimpleMarket memory market = allSimpleMarkets[_marketIndex];
        return market;
    }

    /**
     * Buy a specific market item with Token
     * @param _marketIndex Index of simple market
     * @param _price Payout amount
     */
    function buyFromToken(uint256 _marketIndex, uint256 _price)
        external
        nonReentrant
        returns (bool)
    {
        require(_marketIndex < allSimpleMarkets.length, "Invalid market index");
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];

        require(canClaim(_marketIndex), "withdrawn item");

        // Check if the market is still open
        require(!isSold(_marketIndex), "The market item already sold");

        // Check if payout price is higher or equal with the listed price by owner
        require(_price >= market.currentListingPrice, "New purchase price must be equal or higher than the current listing price");

        // Check if buyer is not the owner
        require(_msgSender() != market.creator, "Creator of the market cannot buy own item");

        // Get ERC20 token contract
        IERC20Upgradeable paymentToken = IERC20Upgradeable(market.addressPaymentToken);

        // Transfer token from buyer to seller to lock the tokens
        require(paymentToken.transferFrom(_msgSender(), address(this), _price), "Tranfer of token failed");

        // Update market info
        address payable newOwner = payable(_msgSender());
        market.currentBuyer = newOwner;
        market.isSold = true;
        simpleMarketSoldIndex++;

        // Trigger public event
        emit ItemPurchasedOnSimpleMarket(_marketIndex, _price);

        return true;
    }

    /**
     * Buy a specific market item with Base Asset - Matic(Polygon)
     * @param _marketIndex Index of simple market
     * @param _price Payout amount
     */
    function buyFromBaseAsset(uint256 _marketIndex, uint256 _price)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(_marketIndex < allSimpleMarkets.length, "Invalid market index");
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];

        require(canClaim(_marketIndex), "withdrawn item");

        // Check if the market is still open
        require(!isSold(_marketIndex), "The market item already sold");

        // Check if payout price is higher or equal with the listed price by owner
        require(_price >= market.currentListingPrice, "New purchase price must be equal or higher than the current listing price");

        // Check if buyer is not the owner
        require(_msgSender() != market.creator, "Creator of the market cannot buy own item");

        // Send the payout to the owner (minus fee)
        require(msg.value == market.currentListingPrice, "Please submit the asking price in order to complete the purchase");
        uint listingFee = (market.currentListingPrice * listingFeeRate) / 10000;
        market.creator.transfer(msg.value - listingFee);
        
        // Get NFT collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(
            market.addressNFTCollection
        );

        // Transfer NFT from Market contract to the new owner
        nftCollection.safeTransferFrom(address(this), _msgSender(), market.nftId, market.nftCount, "");

        // Get market fee to the market operator
        payable(operator).transfer(listingFee);
        
        address payable newOwner = payable(_msgSender());
        market.currentBuyer = newOwner;
        market.isSold = true;
        market.canClaim = false;
        simpleMarketSoldIndex++;

        // Trigger public event
        emit ItemPurchasedOnSimpleMarket(_marketIndex, _price);

        return true;
    }

    /**
     * Function used by the buyer to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the market will receive the payment tokens in his wallet
     * @param _marketIndex Index of auction
     */
    function claimNFTFromSimpleMarket(uint256 _marketIndex) external nonReentrant {
        require(_marketIndex < allSimpleMarkets.length, "Invalid market index");

        // Check if the market is closed
        require(isSold(_marketIndex), "Market item is not sold yet");
        
        require(canClaim(_marketIndex), "Already claimed");

        // Get market
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];

        // Check if the caller is the new owner
        require(market.currentBuyer == _msgSender(), "NFT can be claimed only by the current buyer");

        // Get NFT collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(
            market.addressNFTCollection
        );
        // Transfer NFT from marketplace contract to the new owner
        nftCollection.safeTransferFrom(address(this), market.currentBuyer, market.nftId, market.nftCount, "");
        
        // Get ERC20 Payment token contract
        IERC20Upgradeable paymentToken = IERC20Upgradeable(market.addressPaymentToken);
        
        // Transfer locked token from the Market contract to the previous owner address
        uint listingFee = (market.currentListingPrice * listingFeeRate) / 10000;
        require(paymentToken.transfer(market.creator, market.currentListingPrice - listingFee), "Locked token transfer failed");
        
        // Get market fee to the market operator
        require(paymentToken.transfer(operator, listingFee), "Fee token transfer failed");

        market.canClaim = false;

        emit NFTClaimedFromSimpleMarket(_marketIndex, market.nftId, market.nftCount, _msgSender());
    }

    /**
     * Function used by the creator of an market to withdraw his tokens when the market item is sold
     * When the Token are withdrawn, the buyer of the item will receive the NFT in his walled
     * @param _marketIndex Index of the market
     */
    function claimTokenFromSimpleMarket(uint256 _marketIndex) external nonReentrant {
        require(_marketIndex < allSimpleMarkets.length, "Invalid market index"); // XXX Optimize

        // Check if the market is closed
        require(isSold(_marketIndex), "Market item is not sold yet");

        require(canClaim(_marketIndex), "Already claimed");

        // Get market
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];

        // Check if the caller is the creator of the market
        require(market.creator == _msgSender(), "Tokens can be claimed only by the creator of the market");

        // Get NFT Collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(
            market.addressNFTCollection
        );
        // Transfer NFT from market contract to the new owner
        nftCollection.safeTransferFrom(
            address(this),
            market.currentBuyer,
            market.nftId,
            market.nftCount,
            ""
        );

        // Get ERC20 Payment token contract
        IERC20Upgradeable paymentToken = IERC20Upgradeable(market.addressPaymentToken);
        
        // Transfer locked token from the Market contract to the previous owner address
        uint listingFee = (market.currentListingPrice * listingFeeRate) / 10000;
        require(paymentToken.transfer(market.creator, market.currentListingPrice - listingFee), "Locked token transfer failed");
        
        // Get market fee to the market operator
        require(paymentToken.transfer(operator, listingFee), "Fee token transfer failed");

        market.canClaim = false;

        emit TokensClaimedFromSimpleMarket(_marketIndex, market.nftId, market.nftCount, _msgSender());
    }

    /**
     * Function used by the creator of an market to get his NFT back in case the market item is not sold
     * @param _marketIndex Index of the market
     */
    function refundFromSimpleMarket(uint256 _marketIndex) external nonReentrant {
        require(_marketIndex < allSimpleMarkets.length, "Invalid market index");

        // Check if the market is sold
        require(!isSold(_marketIndex), "The Market item was sold");

        require(canClaim(_marketIndex), "Already claimed");

        // Get market
        SimpleMarket storage market = allSimpleMarkets[_marketIndex];

        // Check if the caller is the creator of the market
        require(market.creator == _msgSender(), "Tokens can be claimed only by the creator of the market");

        require(market.currentBuyer == address(0), "Existing buyer for this market");

        // Get NFT Collection contract
        IKOLLECT1155_V1 nftCollection = IKOLLECT1155_V1(
            market.addressNFTCollection
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the market
        nftCollection.safeTransferFrom(
            address(this),
            market.creator,
            market.nftId,
            market.nftCount,
            ""
        );

        market.canClaim = false;

        emit NFTRefundedFromSimpleMarket(_marketIndex, market.nftId, market.nftCount, _msgSender());
    }

    // Returns all unsold market items
    function fetchMarketItems() public view returns (SimpleMarket[] memory) {
        uint unsoldItemCount = simpleMarketIndex - simpleMarketSoldIndex;
        uint currentIndex = 0;

        SimpleMarket[] memory items = new SimpleMarket[](unsoldItemCount);
        for (uint i = 0; i < simpleMarketIndex; i++) {
            if (!allSimpleMarkets[i].isSold) {
                SimpleMarket storage currentItem = allSimpleMarkets[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns paged sold/unsold market items
    function fetchMarketItemsWithPaging(uint itemsPerPage, uint pageNum, bool soldIncluded) public view 
        returns (SimpleMarket[] memory _items, uint _cursor, uint _itemsPerPage, uint _total) {
        uint unsoldItemCount = 0;
        uint currentIndex = 0;

        uint unboundedLimit = 256;
        uint from = itemsPerPage * pageNum - itemsPerPage;
        uint to = from + itemsPerPage;
        if (from + itemsPerPage > simpleMarketIndex) to = simpleMarketIndex;
        require(itemsPerPage > 0 && pageNum > 0, "fetch params are invalid");
        require((to - from) >= 0 && (to - from) <= unboundedLimit, "fetch size is too big or minus");
        require(from < simpleMarketIndex, "fetch position is invalid");
        
        for (uint i = from; i < to; i++) {
            if (!soldIncluded) {
                if (!allSimpleMarkets[i].isSold) {
                    unsoldItemCount++;
                }
            } else {
                unsoldItemCount++;
            }
        }

        SimpleMarket[] memory items = new SimpleMarket[](unsoldItemCount);
        for (uint i = from; i < to; i++) {
            if (!soldIncluded) {
                if (!allSimpleMarkets[i].isSold) {
                    items[currentIndex] = allSimpleMarkets[i];
                    currentIndex += 1;
                }
            } else {
                items[currentIndex] = allSimpleMarkets[i];
                currentIndex += 1;
            }
        }

        return (items, pageNum, itemsPerPage, simpleMarketIndex);
    }

    // Returns only items that a user has purchased
    function fetchMyMarketItems() public view returns (SimpleMarket[] memory) {
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < simpleMarketIndex; i++) {
            if (allSimpleMarkets[i].currentBuyer == _msgSender()) {
                itemCount += 1;
            }
        }

        SimpleMarket[] memory items = new SimpleMarket[](itemCount);
        for (uint i = 0; i < simpleMarketIndex; i++) {
            if (allSimpleMarkets[i].currentBuyer == _msgSender()) {
                items[currentIndex] = allSimpleMarkets[i];
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyMarketItemsWithPaging(uint itemsPerPage, uint pageNum) public view 
        returns (SimpleMarket[] memory _items, uint _cursor, uint _itemsPerPage, uint _total) {
        uint itemCount = 0;
        uint currentIndex = 0;

        uint unboundedLimit = 256;
        uint from = itemsPerPage * pageNum - itemsPerPage;
        uint to = from + itemsPerPage;
        if (from + itemsPerPage > simpleMarketIndex) to = simpleMarketIndex;
        require(itemsPerPage > 0 && pageNum > 0, "fetch params are invalid");
        require((to - from) >= 0 && (to - from) <= unboundedLimit, "fetch size is too big or minus");
        require(from < simpleMarketIndex, "fetch position is invalid");

        for (uint i = from; i < to; i++) {
            if (allSimpleMarkets[i].currentBuyer == _msgSender()) {
                itemCount += 1;
            }
        }

        SimpleMarket[] memory items = new SimpleMarket[](itemCount);
        if (itemCount == 0) return (items, pageNum, itemsPerPage, simpleMarketIndex);

        for (uint i = from; i < to; i++) {
            if (allSimpleMarkets[i].currentBuyer == _msgSender()) {
                items[currentIndex] = allSimpleMarkets[i];
                currentIndex += 1;
            }
        }

        return (items, pageNum, itemsPerPage, simpleMarketIndex);
    }

    // Returns only items a user has created
    function fetchMarketItemsCreated() public view returns (SimpleMarket[] memory) {
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < simpleMarketIndex; i++) {
            if (allSimpleMarkets[i].creator == _msgSender()) {
                itemCount += 1;
            }
        }

        SimpleMarket[] memory items = new SimpleMarket[](itemCount);
        for (uint i = 0; i < simpleMarketIndex; i++) {
            if (allSimpleMarkets[i].creator == _msgSender()) {
                SimpleMarket storage currentItem = allSimpleMarkets[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMarketItemsCreatedWithPaging(uint itemsPerPage, uint pageNum) public view 
        returns (SimpleMarket[] memory _items, uint _cursor, uint _itemsPerPage, uint _total) {
        uint itemCount = 0;
        uint currentIndex = 0;

        uint unboundedLimit = 256;
        uint from = itemsPerPage * pageNum - itemsPerPage;
        uint to = from + itemsPerPage;
        if (from + itemsPerPage > simpleMarketIndex) to = simpleMarketIndex;
        require(itemsPerPage > 0 && pageNum > 0, "fetch params are invalid");
        require((to - from) >= 0 && (to - from) <= unboundedLimit, "fetch size is too big or minus");
        require(from < simpleMarketIndex, "fetch position is invalid");

        for (uint i = from; i < to; i++) {
            if (allSimpleMarkets[i].creator == _msgSender()) {
                itemCount += 1;
            }
        }

        SimpleMarket[] memory items = new SimpleMarket[](itemCount);
        if (itemCount == 0) return (items, itemCount, itemsPerPage, simpleMarketIndex);

        for (uint i = from; i < to; i++) {
            if (allSimpleMarkets[i].creator == _msgSender()) {
                items[currentIndex] = allSimpleMarkets[i];
                currentIndex += 1;
            }
        }
        
        return (items, pageNum, itemsPerPage, simpleMarketIndex);
    }
}