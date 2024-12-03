// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {VennFirewallConsumer} from "@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";
import {ErrorLibrary} from "../../library/ErrorLibrary.sol";

import {OwnableCheck} from "./OwnableCheck.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable-4.9.6/proxy/utils/Initializable.sol";

/**
 * @title OracleManagement
 * @notice Handles updating and interacting with the price oracle for the platform.
 * Allows updating the oracle address used across the platform for price data.
 */
abstract contract OracleManagement is VennFirewallConsumer, OwnableCheck, Initializable {
  IPriceOracle public oracle;

  event OracleUpdated(address indexed oldOracle, address indexed newOracle);

  // Initializes the oracle address. Meant to be called by inheriting contract's initializer or constructor.
  function __OracleManagement_init(address _oracle) internal onlyInitializing {
    _updatePriceOracle(_oracle);
  }

  /**
   * @dev Updates the price oracle contract address.
   * @param _newOracle Address of the new price oracle contract.
   */
  function updatePriceOracle(address _newOracle) external onlyProtocolOwner firewallProtected {
    _updatePriceOracle(_newOracle);
    emit OracleUpdated(address(oracle), _newOracle);
  }

  /**
   * @dev Internal function to add update the price oracle address.
   * @param _newOracle address of oracle to update the oracle.
   */
  function _updatePriceOracle(address _newOracle) internal {
    if (_newOracle == address(0)) revert ErrorLibrary.InvalidOracleAddress();
    oracle = IPriceOracle(_newOracle);
  }
}
