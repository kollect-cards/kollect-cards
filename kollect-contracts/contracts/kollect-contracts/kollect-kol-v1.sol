// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract KollectKOL_V1 is Initializable, OwnableUpgradeable, ERC20PresetMinterPauserUpgradeable, UUPSUpgradeable {

    function initialize(string memory name, string memory symbol, uint256 initialSupply) public virtual initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
        _mint(_msgSender(), initialSupply);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}