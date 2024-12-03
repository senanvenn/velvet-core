// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {VennFirewallConsumer} from "@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/UUPSUpgradeable.sol";

import {OracleManagement, IPriceOracle, OwnableCheck} from "./OracleManagement.sol";
import {ProtocolTreasuryManagement} from "./ProtocolTreasuryManagement.sol";
import {SystemSettings} from "./SystemSettings.sol";
import {TokenManagement} from "./TokenManagement.sol";
import {ProtocolFeeManagement} from "./ProtocolFeeManagement.sol";
import {SolverManagement} from "./SolverManagement.sol";

import {RewardTargetManagement} from "./RewardTargetManagement.sol";

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/utils/ContextUpgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title MainContract
 * @dev Main contract integrating all management functionalities with access control.
 */
contract ProtocolConfig is
  VennFirewallConsumer,
  Ownable2StepUpgradeable,
  UUPSUpgradeable,
  OracleManagement,
  ProtocolTreasuryManagement,
  SystemSettings,
  TokenManagement,
  ProtocolFeeManagement,
  SolverManagement,
  RewardTargetManagement
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // Implement the OwnableUpgradeable initialization.
  function initialize(
    address _velvetTreasury,
    address _oracle
  ) external initializer firewallProtected {
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __OracleManagement_init(_oracle);
    __TreasuryManagement_init(_velvetTreasury);
    __SystemSettings_init();
    __TokenManagement_init(_oracle);
    __FeeManagement_init();
  
		_setAddressBySlot(bytes32(uint256(keccak256("eip1967.firewall")) - 1), address(0));
		_setAddressBySlot(bytes32(uint256(keccak256("eip1967.firewall.admin")) - 1), msg.sender);
	}

  function _owner() internal view override(OwnableCheck) returns (address) {
    return owner();
  }

  // Override the onlyOwner modifier to specify it overrides from OwnableUpgradeable.
  function _isOwner()
    internal
    view
    override(OwnableCheck)
    onlyOwner
    returns (bool)
  {
    return true;
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
