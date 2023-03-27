// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IKOLLECT1155_V1 is IERC1155Upgradeable {
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override;
    
    function uri(uint256 id) external view returns (string memory);
    
    function getTokens(address account) external view returns (uint256[] memory);
    
    function getTokensAndAmounts(address account) external view returns (uint256[] memory, uint256[] memory);
    
    function mint(address account, uint256 id, uint256 amount, string calldata newUri) external;
    
    function mintBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external;
    
    function burn(address account, uint256 id, uint256 amount) external;
    
    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external;
    
    function setURI(string calldata uri_) external;
}