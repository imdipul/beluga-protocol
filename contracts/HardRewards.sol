pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Governable.sol";
import "./Controllable.sol";

contract HardRewards is Controllable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Rewarded(address indexed recipient, address indexed vault, uint256 amount);

  // Token used for rewards
  IERC20 public token;

  // How many rewards for each harvest
  uint256 public rewardRate;

  // Vault to the last rewarded block
  mapping(address => uint256) public lastReward;

  constructor(address _storage, address _token)
  Controllable(_storage) public {
    token = IERC20(_token);
  }

  /**
  * Called from the controller after hard work has been done. Defensively avoid
  * reverting the transaction in this function.
  */
  function rewardMe(address recipient, address vault) external onlyController {
    if (address(token) == address(0) || rewardRate == 0) {
      // no rewards now
      emit Rewarded(recipient, vault, 0);
      return;
    }

    if (lastReward[vault] == 0) {
      // Vault does not exist
      emit Rewarded(recipient, vault, 0);
      return;
    }

    if (rewardRate > 0) {
      uint256 balance = token.balanceOf(address(this));
      uint256 realReward = balance >= rewardRate ? rewardRate : balance;
      if (realReward > 0) {
        token.safeTransfer(recipient, realReward);
      }
      emit Rewarded(recipient, vault, realReward);
    } else {
      emit Rewarded(recipient, vault, 0);
    }
    lastReward[vault] = block.number;
  }

  function addVault(address _vault) external onlyGovernance {
    lastReward[_vault] = block.number;
  }

  function removeVault(address _vault) external onlyGovernance {
    delete (lastReward[_vault]);
  }

  /**
  * Transfers tokens for the new rewards cycle. Allows for changing the rewards setting
  * at the same time.
  */
  function load(address _token, uint256 _rate, uint256 _amount) external onlyGovernance {
    token = IERC20(_token);
    rewardRate = _rate;
    if (address(token) != address(0) && _amount > 0) {
      token.safeTransferFrom(msg.sender, address(this), _amount);
    }
  }
}