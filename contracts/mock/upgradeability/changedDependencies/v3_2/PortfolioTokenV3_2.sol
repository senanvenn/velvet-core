// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {VennFirewallConsumer} from "@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/token/ERC20/ERC20Upgradeable.sol";
import {AccessModifiers} from "../../../../core/access/AccessModifiers.sol";
import {CooldownManager, ErrorLibrary} from "../../../../core/cooldown/CooldownManager.sol";
import {Dependencies} from "../../../../core/config/Dependencies.sol";
import {UserManagementV3_2} from "./UserManagementV3_2.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable-4.9.6/utils/ContextUpgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title PortfolioToken
 * @notice Represents a tokenized share of the portfolio fund, facilitating deposit and withdrawal by minting and burning portfolio tokens.
 * @dev Inherits from ERC20Upgradeable for standard token functionality, and utilizes various contracts for managing access controls,
 * cooldown periods, dependency configurations, and user-related functionalities.
 */
abstract contract PortfolioTokenV3_2 is
  VennFirewallConsumer,
  ERC20Upgradeable,
  AccessModifiers,
  CooldownManager,
  Dependencies,
  UserManagementV3_2
{
  // Initializes the contract with a name and symbol for the ERC20 token.
  function __PortfolioToken_init(
    string calldata _name,
    string calldata _symbol
  ) internal {
    __ERC20_init(_name, _symbol);
  }

  /**
   * @notice Mints portfolio tokens to a specified address.
   * @dev Only callable by an address with the minter role. This function increases the recipient's balance by the specified amount.
   * @param _to The recipient address.
   * @param _amount The amount of tokens to mint.
   */
  function mintShares(address _to, uint256 _amount) external onlyMinter firewallProtected {
    _mint(_to, _amount);
  }

  /**
   * @notice Checks if the fee value is greater than zero and the recipient is not one of the special treasury addresses.
   * @dev Used internally to validate fee transactions.
   * @param _fee The fee amount being checked.
   * @param _to The recipient of the fee.
   * @return bool Returns true if the conditions are met, false otherwise.
   */
  function _mintAndBurnCheck(
    uint256 _fee,
    address _to
  ) internal returns (bool) {
    return (_fee > 0 &&
      !(_to == assetManagementConfig().assetManagerTreasury() ||
        _to == protocolConfig().velvetTreasury()));
  }

  /**
   * @notice Mints new portfolio tokens, considering the entry fee, if applicable, and assigns them to the specified address.
   * @param _to Address to which the minted tokens will be assigned.
   * @param _mintAmount Amount of portfolio tokens to mint.
   * @return The amount of tokens minted after deducting any entry fee.
   */
  function _mintTokenAndSetCooldown(
    address _to,
    uint256 _mintAmount
  ) internal returns (uint256) {
    uint256 entryFee = assetManagementConfig().entryFee();

    if (_mintAndBurnCheck(entryFee, _to)) {
      _mintAmount = feeModule()._chargeEntryOrExitFee(_mintAmount, entryFee);
    }

    _mint(_to, _mintAmount);

    // Updates the cooldown period based on the minting action.
    userCooldownPeriod[_to] = _calculateCooldownPeriod(
      balanceOf(_to),
      _mintAmount,
      protocolConfig().cooldownPeriod(),
      userCooldownPeriod[_to],
      userLastDepositTime[_to]
    );
    userLastDepositTime[_to] = block.timestamp;

    return _mintAmount;
  }

  /**
   * @notice Burns a specified amount of portfolio tokens from an address, considering the exit fee, if applicable.
   * @param _to Address from which the tokens will be burned.
   * @param _mintAmount Amount of portfolio tokens to burn.
   * @return afterFeeAmount The amount of tokens burned after deducting any exit fee.
   */
  function _burnWithdraw(
    address _to,
    uint256 _mintAmount
  ) internal returns (uint256 afterFeeAmount) {
    uint256 exitFee = assetManagementConfig().exitFee();

    afterFeeAmount = _mintAmount;
    if (_mintAndBurnCheck(exitFee, _to)) {
      afterFeeAmount = feeModule()._chargeEntryOrExitFee(_mintAmount, exitFee);
    }

    _burn(_to, _mintAmount);

    return afterFeeAmount;
  }

  /**
   * @notice Enforces checks before token transfers, such as transfer restrictions and cooldown periods.
   * @param from Address sending the tokens.
   * @param to Address receiving the tokens.
   * @param amount Amount of tokens being transferred.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);
    if (from == address(0) || to == address(0)) {
      return;
    }
    if (
      !(assetManagementConfig().transferableToPublic() ||
        (assetManagementConfig().transferable() &&
          assetManagementConfig().whitelistedUsers(to)))
    ) {
      revert ErrorLibrary.Transferprohibited();
    }
    _checkCoolDownPeriod(from);
  }

  /**
   * @notice Updates user records after token transfers to ensure accurate tracking of user balances (for token removal - UserManagement).
   * @param _from Address of the sender in the transfer.
   * @param _to Address of the recipient in the transfer.
   * @param _amount Amount of tokens transferred.
   */
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    super._afterTokenTransfer(_from, _to, _amount);
    if (_from == address(0)) {
      _updateUserRecord(_to, balanceOf(_to));
    } else if (_to == address(0)) {
      _updateUserRecord(_from, balanceOf(_from));
    } else {
      _updateUserRecord(_from, balanceOf(_from));
      _updateUserRecord(_to, balanceOf(_to));
    }
  }

  function _msgData() internal view virtual override(ContextUpgradeable, Context) returns (bytes calldata) {
    return ContextUpgradeable._msgData();
  }

  function _msgSender() internal view virtual override(ContextUpgradeable, Context) returns (address) {
    return ContextUpgradeable._msgSender();
  }
}
