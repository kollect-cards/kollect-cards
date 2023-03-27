// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract KollectRolesUpgradeable is 
    Initializable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("KOLLECT_MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("KOLLECT_BURNER");
    bytes32 public constant MANAGER_ROLE = keccak256("KOLLECT_MANAGER");

    function __KollectRoles_V1_init() internal onlyInitializing {
    }

    function __KollectRoles_V1_init_unchained() internal onlyInitializing {
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Roles: caller does not have the ADMIN role");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Roles: caller does not have the MINTER role");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "Roles: caller does not have the BURNER role");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Roles: caller does not have the MANAGER role");
        _;
    }
}
