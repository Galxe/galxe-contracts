// SPDX-License-Identifier: Apache-2.0

/*
     Copyright 2023 Galxe.

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title GalxePlus
 * @author Galxe
 *
 * GalxePlus contract allows users to subscribe to the GalxePlus service.
 */
contract GalxePlus is Ownable {
    event SetPlan(uint64 id, address token, uint256 amount, uint64 durationSeconds);

    event Subscribe(address indexed user, bytes32 galxeId, uint64 planId, uint256 amount);

    event EnableAutoRenew(address indexed user);

    event DisableAutoRenew(address indexed user);

    event ExtendPlan(address indexed user, uint64 planId, uint256 amount);

    event UpgradePlan(address indexed user, uint64 planId, uint256 amount);

    event UnStake(address indexed user, uint256 amount);

    modifier onlySubscriber() {
        _onlySubscriber();
        _;
    }

    modifier onlySubscribedPreviously() {
        _onlySubscribedPreviously();
        _;
    }

    function _onlySubscriber() internal view {
        require(addressToSubscription[msg.sender].planId != 0, "You have not subscribed yet");
        require(addressToSubscription[msg.sender].expiredAt > block.timestamp, "Your subscription has expired");
    }

    function _onlySubscribedPreviously() internal view {
        require(addressToSubscription[msg.sender].planId != 0, "You have never subscribed before.");
    }

    struct Subscription {
        uint64 planId;
        uint64 createdAt;
        uint64 expiredAt;
        uint64 isOpenAutoRenew; // uint64 for 256 alignment
    }

    struct PlanConfig {
        uint64 id;
        address token;
        uint256 amount;
        uint64 durationSeconds;
    }

    // address => Subscription
    mapping(address => Subscription) public addressToSubscription;

    // Mapping that stores all fee requirements for a given activated Subscription.
    mapping(uint64 => PlanConfig) public planConfigs;

    // Mapping that stores stake amount for a given user.
    mapping(address => uint256) public addressToStakeAmount;

    constructor(address owner) {
        transferOwnership(owner);
    }

    /**
     * * @dev Activate a new plan.
     */
    function setPlan(uint64 _id, address _token, uint256 _amount, uint64 _durationSeconds) external onlyOwner {
        _setPlan(_id, _token, _amount, _durationSeconds);
        emit SetPlan(_id, _token, _amount, _durationSeconds);
    }

    /**
     * * @dev Get plan by pid.
     */
    function getPlan(uint64 _pid) external view returns (PlanConfig memory) {
        return planConfigs[_pid];
    }

    /**
     * * @dev Get subscription by user address.
     */
    function getSubscription(address user) external view returns (Subscription memory) {
        return addressToSubscription[user];
    }

    /**
     * * @dev Get stake record by user address.
     */
    function getStakeAmount(address _user) external view returns (uint256) {
        return addressToStakeAmount[_user];
    }

    /**
     * * @dev Subscribe to a plan.
     */
    function subscribe(uint64 _pid, bytes32 _galxeId, bool _autoRenew) external {
        _subscribe(_pid, msg.sender, _galxeId, _autoRenew);
    }

    /**
     * * @dev Subscribe to a plan.
     */
    function subscribe(uint64 _pid, address _user, bytes32 _galxeId, bool _autoRenew) external {
        _subscribe(_pid, _user, _galxeId, _autoRenew);
    }

    /**
     * * @dev Enable auto-renewal.
     */
    function enableAutoRenew() external onlySubscribedPreviously {
        Subscription storage subscription = addressToSubscription[msg.sender];

        require(!_isOpenAutoRenew(subscription), "Auto-renewal has been enabled");

        subscription.isOpenAutoRenew = 1;
        subscription.expiredAt = type(uint64).max;

        emit EnableAutoRenew(msg.sender);
    }

    /**
     * * @dev Disable auto-renewal.
     */
    function disableAutoRenew() external onlySubscriber {
        Subscription storage subscription = addressToSubscription[msg.sender];

        require(_isOpenAutoRenew(subscription), "Auto-renewal has been disabled");

        subscription.isOpenAutoRenew = 0;
        subscription.expiredAt = _getExpiredAt(subscription);

        emit DisableAutoRenew(msg.sender);
    }

    /**
     * * @dev Switch to annual plan. Only for Monthly plan.
     */
    function extendPlan(uint64 _pid) external onlySubscriber {
        Subscription storage subscription = addressToSubscription[msg.sender];
        PlanConfig storage prePlanConf = planConfigs[subscription.planId];
        PlanConfig storage curPlanConf = planConfigs[_pid];

        require(
            curPlanConf.durationSeconds > prePlanConf.durationSeconds, "Only support switch to longer commitment plan"
        );

        uint256 transferAmount = _changePlan(subscription, curPlanConf, true);

        emit ExtendPlan(msg.sender, _pid, transferAmount);
    }

    /**
     * * @dev Upgrade plan.
     */
    function upgradePlan(uint64 _pid) external onlySubscriber {
        Subscription storage subscription = addressToSubscription[msg.sender];
        PlanConfig storage prePlanConf = planConfigs[subscription.planId];
        PlanConfig storage curPlanConf = planConfigs[_pid];

        require(curPlanConf.amount > prePlanConf.amount, "Only support upgrade version");

        uint256 transferAmount = _changePlan(subscription, curPlanConf, false);

        emit UpgradePlan(msg.sender, _pid, transferAmount);
    }

    /**
     * * @dev Unstake GAL
     */
    function unStake() external onlySubscribedPreviously {
        Subscription storage subscription = addressToSubscription[msg.sender];
        uint256 stakeAmount = addressToStakeAmount[msg.sender];
        PlanConfig storage planConfig = planConfigs[subscription.planId];

        require(!_isOpenAutoRenew(subscription), "Auto-renewal enabled,operation denied.");

        require(subscription.expiredAt < block.timestamp, "Staking period has not ended yet.");

        require(stakeAmount != 0, "You have already unstaked.");

        delete addressToStakeAmount[msg.sender];
        _transferToken(address(this), msg.sender, planConfig.token, stakeAmount);

        emit UnStake(msg.sender, stakeAmount);
    }

    /**
     * * @dev Change plan by StakeGAL. Switch to annual plan or upgrade plan.
     */
    function _changePlan(Subscription storage _subscription, PlanConfig storage _plan, bool isExtend)
        private
        returns (uint256 _transferAmount)
    {
        uint256 stakeAmount = addressToStakeAmount[msg.sender];

        if (stakeAmount > _plan.amount) {
            _transferAmount = stakeAmount - _plan.amount;
            _transferToken(address(this), msg.sender, _plan.token, _transferAmount);
        } else {
            _transferAmount = _plan.amount - stakeAmount;
            _transferToken(msg.sender, address(this), _plan.token, _transferAmount);
        }
        _subscription.planId = _plan.id;
        if (isExtend && !_isOpenAutoRenew(_subscription)) {
            _subscription.expiredAt = _getExpiredAt(_subscription);
        }

        addressToStakeAmount[msg.sender] = _plan.amount;
    }

    /**
     * * @dev Set fees for a given plan.
     */
    function _setPlan(uint64 _id, address _token, uint256 _amount, uint64 _durationSeconds) private {
        require(_id != 0, "Invalid id");

        require(_durationSeconds != 0, "Invalid durationSeconds");

        require(_token != address(0) && _amount != 0, "Invalid token requirement arguments");

        PlanConfig storage plan = planConfigs[_id];

        require(plan.durationSeconds == 0, "The plan already exists");

        plan.id = _id;
        plan.token = _token;
        plan.amount = _amount;
        plan.durationSeconds = _durationSeconds;
    }

    /**
     * * @dev Subscribe to a plan.
     */
    function _subscribe(uint64 _pid, address _user, bytes32 _galxeId, bool _autoRenew) private {
        Subscription storage subscription = addressToSubscription[_user];
        uint256 stakeAmount = addressToStakeAmount[_user];

        require(planConfigs[_pid].token != address(0), "Invalid plan");

        require(
            subscription.planId == 0 || subscription.expiredAt < block.timestamp,
            "You currently have an active subscription plan. You cannot subscribe again."
        );

        uint256 transferAmount = 0;
        if (planConfigs[_pid].amount > stakeAmount) {
            transferAmount = planConfigs[_pid].amount - stakeAmount;
            _transferToken(_user, address(this), planConfigs[_pid].token, transferAmount);
        } else {
            transferAmount = stakeAmount - planConfigs[_pid].amount;
            _transferToken(address(this), _user, planConfigs[_pid].token, transferAmount);
        }

        subscription.planId = _pid;
        subscription.isOpenAutoRenew = _autoRenew == true ? 1 : 0;
        subscription.createdAt = uint64(block.timestamp);
        subscription.expiredAt = _getExpiredAt(subscription);

        addressToStakeAmount[_user] = planConfigs[_pid].amount;
        emit Subscribe(_user, _galxeId, _pid, transferAmount);
    }

    /**
     * * @dev Pay fees for a given plan.
     */
    function _transferToken(address from, address to, address token, uint256 amount) private {
        if (from == address(this)) {
            require(IERC20(token).transfer(to, amount), "Transfer erc20Fee failed");
        } else {
            require(IERC20(token).transferFrom(from, to, amount), "Transfer erc20Fee failed");
        }
    }

    /**
     * * @dev calc exiredAt
     */
    function _getExpiredAt(Subscription storage subscription) private view returns (uint64) {
        if (_isOpenAutoRenew(subscription)) {
            return type(uint64).max;
        }
        PlanConfig storage plan = planConfigs[subscription.planId];
        uint64 timeDifference = uint64(block.timestamp) - subscription.createdAt;
        uint64 rounds = timeDifference / plan.durationSeconds;

        if (timeDifference == 0 || timeDifference % plan.durationSeconds > 0) {
            rounds++;
        }
        return rounds * plan.durationSeconds + subscription.createdAt;
    }

    function _isOpenAutoRenew(Subscription storage subscription) private view returns (bool) {
        return subscription.isOpenAutoRenew == 1 ? true : false;
    }
}
