// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {VennFirewallConsumer} from "@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol";

import {TreasuryManagement} from "./TreasuryManagement.sol";
import {PortfolioSettings, AssetManagerCheck} from "./PortfolioSettings.sol";
import {TokenWhitelistManagement} from "./TokenWhitelistManagement.sol";
import {UserWhitelistManagement} from "./UserWhitelistManagement.sol";
import {FeeManagement} from "./FeeManagement.sol";

import {FunctionParameters} from "../../FunctionParameters.sol";

import {AccessRoles} from "../../access/AccessRoles.sol";

import {IAccessController} from "../../access/IAccessController.sol";

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/utils/ContextUpgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title MainContract
 * @dev Main contract integrating all management functionalities with access control.
 */
contract AssetManagementConfig is
  VennFirewallConsumer,
  OwnableUpgradeable,
  UUPSUpgradeable,
  TreasuryManagement,
  PortfolioSettings,
  TokenWhitelistManagement,
  FeeManagement,
  UserWhitelistManagement,
  AccessRoles
{
  IAccessController internal accessController;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // Implement the OwnableUpgradeable initialization.
  function init(
    FunctionParameters.AssetManagementConfigInitData calldata initData
  ) external initializer firewallProtected {
    __Ownable_init();
    __UUPSUpgradeable_init();

    accessController = IAccessController(initData._accessController);

    // init parents
    __TreasuryManagement_init(initData._assetManagerTreasury);

    __PortfolioSettings_init(
      initData._protocolConfig,
      initData._initialPortfolioAmount,
      initData._minPortfolioTokenHoldingAmount,
      initData._publicPortfolio,
      initData._transferable,
      initData._transferableToPublic
    );

    __TokenWhitelistManagement_init(
      initData._whitelistedTokens,
      initData._whitelistTokens,
      initData._protocolConfig
    );

    __FeeManagement_init(
      initData._protocolConfig,
      initData._managementFee,
      initData._performanceFee,
      initData._entryFee,
      initData._exitFee,
      initData._feeModule
    );

    __UserWhitelistManagement_init(initData._protocolConfig);
  
		_setAddressBySlot(bytes32(uint256(keccak256("eip1967.firewall")) - 1), address(0));
		_setAddressBySlot(bytes32(uint256(keccak256("eip1967.firewall.admin")) - 1), msg.sender);
	}

  // Override the onlyOwner modifier to specify it overrides from OwnableUpgradeable.
  function _isAssetManager()
    internal
    view
    override(AssetManagerCheck)
    returns (bool)
  {
    return accessController.hasRole(ASSET_MANAGER, msg.sender);
  }

  // Override the onlyOwner modifier to specify it overrides from OwnableUpgradeable.
  function _isWhitelistManager()
    internal
    view
    override(AssetManagerCheck)
    returns (bool)
  {
    return accessController.hasRole(WHITELIST_MANAGER, msg.sender);
  }

  /**
   * @notice Authorizes upgrade for this contract
   * @param newImplementation Address of the new implementation
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {
    // Intentionally left empty as required by an abstract contract
  }

  function _msgData() internal view virtual override(ContextUpgradeable, Context) returns (bytes calldata) {
    return ContextUpgradeable._msgData();
  }

  function _msgSender() internal view virtual override(ContextUpgradeable, Context) returns (address) {
    return ContextUpgradeable._msgSender();
  }
}
