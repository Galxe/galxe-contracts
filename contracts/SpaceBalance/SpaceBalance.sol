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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title SpaceBalance
 * @author Galxe
 *
 * SpaceBalance contract allows Galxe to charge and keep track of Galxe Space balances.
 */
contract SpaceBalance is Pausable, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Events ============ */

    event UpdateTreasurer(address indexed newTreasurer);

    event Deposit(uint256 indexed _space, IERC20 indexed token, uint256 _amount, address indexed depositor);

    event Withdraw(uint256 indexed _space, IERC20 token, uint256 indexed _amount, address indexed recipient);

    event AllowToken(IERC20 indexed token);

    event DisallowToken(IERC20 indexed token);

    /* ============ Modifiers ============ */

    modifier onlyTreasurer() {
        _onlyTreasurer();
        _;
    }

    modifier onlyAllowedToken(IERC20 token) {
        _onlyAllowedToken(token);
        _;
    }

    function _onlyTreasurer() internal view {
        require(msg.sender == treasurer, "Must be treasurer");
    }

    function _onlyAllowedToken(IERC20 token) internal view {
        require(tokenAllowlist[token] == true, "Must be allowed token");
    }

    /* ============ State Variables ============ */

    // Contract factory
    address public factory;

    // Galxe treasurer
    address public treasurer;

    // Galxe Space => token => current balance
    mapping(uint256 => mapping(IERC20 => uint256)) public spaceTokenBalance;

    // Galxe Space => token => total deposited amount
    mapping(uint256 => mapping(IERC20 => uint256)) public spaceTotalDeposits;

    // Allowed ERC20 tokens
    mapping(IERC20 => bool) public tokenAllowlist;

    /* ============ Constructor ============ */

    constructor() {
        factory = msg.sender;
    }

    /* ============ Initializer ============ */

    function initialize(address owner, address _treasurer) external {
        require(msg.sender == factory, "Forbidden");
        treasurer = _treasurer;
        transferOwnership(owner);
    }

    /* ============ External Functions ============ */

    function setTreasurer(address _treasurer) external onlyOwner {
        require(_treasurer != address(0), "Treasurer address must not be null address");
        treasurer = _treasurer;
        emit UpdateTreasurer(_treasurer);
    }

    function allowToken(IERC20 _token) external onlyOwner {
        tokenAllowlist[_token] = true;

        emit AllowToken(_token);
    }

    function disallowToken(IERC20 _token) external onlyOwner {
        tokenAllowlist[_token] = false;

        emit DisallowToken(_token);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function isTokenAllowed(IERC20 _token) public view returns (bool) {
        return tokenAllowlist[_token];
    }

    function balanceOf(uint256 _space, IERC20 _token) public view returns (uint256) {
        return spaceTokenBalance[_space][_token];
    }

    /**
     * @notice
     *  Returns accumulated token disposit amount for space.
     */
    function totalDepositOf(uint256 _space, IERC20 _token) public view returns (uint256) {
        return spaceTotalDeposits[_space][_token];
    }

    function deposit(uint256 _space, IERC20 _token, uint256 _amount) external whenNotPaused onlyAllowedToken(_token) {
        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "Your token amount must be greater then you are trying to deposit"
        );
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "Approve tokens first!");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        spaceTokenBalance[_space][_token] += _amount;
        spaceTotalDeposits[_space][_token] += _amount;

        emit Deposit(_space, _token, _amount, msg.sender);
    }

    function withdraw(uint256 _space, IERC20 _token, address _recipient) external whenNotPaused onlyTreasurer {
        uint256 _amount = spaceTokenBalance[_space][_token];
        _withdraw(_space, _token, _amount, _recipient);
    }

    function withdraw(
        uint256 _space,
        IERC20 _token,
        uint256 _amount,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        _withdraw(_space, _token, _amount, _recipient);
    }

    function _withdraw(uint256 _space, IERC20 _token, uint256 _amount, address _recipient) internal {
        require(_amount > 0, "Cannot withdraw a non-positive amount");
        require(spaceTokenBalance[_space][_token] >= _amount, "Token amount must be greater than withdraw amount");
        spaceTokenBalance[_space][_token] -= _amount;
        _token.safeTransfer(_recipient, _amount);
        emit Withdraw(_space, _token, _amount, _recipient);
    }

    function withdrawBatch(
        uint256 _space,
        IERC20[] calldata _tokens,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; ++i) {
            _amounts[i] = spaceTokenBalance[_space][_tokens[i]];
        }
        _withdrawBatch(_space, _tokens, _amounts, _recipient);
    }

    function withdrawBatch(
        uint256 _space,
        IERC20[] calldata _tokens,
        uint256[] memory _amounts,
        address _recipient
    ) external whenNotPaused onlyTreasurer {
        _withdrawBatch(_space, _tokens, _amounts, _recipient);
    }

    function _withdrawBatch(
        uint256 _space,
        IERC20[] calldata _tokens,
        uint256[] memory _amounts,
        address _recipient
    ) internal {
        require(_tokens.length == _amounts.length, "Tokens and amounts length mismatch");
        for (uint256 i = 0; i < _amounts.length; ++i) {
            uint256 _amount = _amounts[i];
            IERC20 _token = _tokens[i];
            _withdraw(_space, _token, _amount, _recipient);
        }
    }
}
