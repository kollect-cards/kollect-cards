// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract KollectNFT_V2 is 
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    UUPSUpgradeable
{
    string private _uri;
    mapping (uint256 => string) private _uris;
    mapping (address => uint256[]) private _addressToTokens;

    function initialize() public initializer {
        __ERC1155_init(_uri);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
    
    function arrayPush(uint[] storage input, uint element) internal {
        if (input.length == 0) {
            input.push(element);
        } else {
            for (uint i = 0; i < input.length; i++)
            {
                if (input[i] == element) {
                    return;
                }
            }
            
            input.push(element);
        }
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        arrayPush(_addressToTokens[to], id);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            arrayPush(_addressToTokens[to], id);
        }
    }
    
    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(_uris[id]).length != 0) return _uris[id];
        else return _uri;
    }
    
    function getTokens(address account) public view returns (uint256[] memory) {
        return _addressToTokens[account];
    }
    
    function getTokensAndAmounts(address account) public view returns (uint256[] memory, uint256[] memory) {
        uint length = _addressToTokens[account].length;
        uint256[] memory ids = new uint256[](length);
        uint256[] memory amounts = new uint256[](length);
        for (uint i = 0; i < length; i++) {
            uint id = _addressToTokens[account][i];
            ids[i] = id;
            amounts[i] = balanceOf(account, id);
        }
        return (ids, amounts);
    }

    function mint(address account, uint256 id, uint256 amount, string calldata newUri) public onlyOwner {
        _mint(account, id, amount, "");
        arrayPush(_addressToTokens[account], id);
        if (bytes(newUri).length != 0) {
            _uris[id] = newUri;
        }
    }
    
    function mintBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
        _mintBatch(account, ids, amounts, "");
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            arrayPush(_addressToTokens[account], id);
        }
    }
    
    function burn(address account, uint256 id, uint256 amount) public {
        require(_msgSender() == account);
        _burn(account, id, amount);
    }
    
    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) public {
        require(_msgSender() == account);
        _burnBatch(account, ids, amounts);
    }
    
    function setURI(string calldata uri_) public onlyOwner {
        _uri = uri_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function version() public pure returns (string memory) {
        return "Kollect NFT V2";
    }
}