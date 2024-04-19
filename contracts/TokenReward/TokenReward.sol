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

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {Address} from "@openzeppelin-v3/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin-v3/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin-v3/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "@openzeppelin-v3/contracts/drafts/EIP712.sol";
import {ECDSA} from "@openzeppelin-v3/contracts/cryptography/ECDSA.sol";

/**
 * @title TokenReward
 * @author Galxe
 *
 * TokenReward contract that allows privileged DAOs to initiate token reward campaigns for members to claim token reward.
 */
contract TokenReward is EIP712 {
    using Address for address;
    using SafeMath for uint256;

    /* ============ Events ============ */
    event EventPausedUpdate(bool _oldStatus, bool _newStatus);
    event EventOwnerUpdate(address _oldOwner, address _newOwner);
    event EventSignerUpdate(address _oldSigner, address _newSigner);

    event EventWhitelistTokenAdd(address _token);
    event EventWhitelistTokenRemove(address _token);

    event EventActivateCampaign(
        uint256 indexed cid,
        address admin,
        address token,
        uint256 amountPerAddress,
        uint256 totalAddress
    );

    event EventCampaignAdminUpdate(uint256 indexed _cid, address _oldAdmin, address _newAdmin);

    event EventWithdraw(uint256 indexed _cid, address _token, uint256 _amount, address _admin);

    event EventClaim(
        uint256 indexed _cid,
        address _token,
        uint256 _amount,
        uint256 _dummyId,
        address _claimTo
    );


    /* ============ Modifiers ============ */

    /**
     * Throws if the contract paused
     */
    modifier onlyNotPaused() {
        _validateOnlyNotPaused();
        _;
    }

    /* ============ Structs ============ */

    struct CampaignConfig {
        address admin; // campaign admin, only admin can withdraw
        address token; // zero address is native token.
        uint256 amountPerAddress;
        uint128 totalAddress;
        uint128 claimed; // count of claimed the reward
    }

    /* ============ State Variables ============ */
    // Is contract paused.
    bool public paused;

    // Contract owner
    address public owner;

    // Galxe Signer
    address public signer;

    // Campaign configuration
    mapping(uint256 => CampaignConfig) public campaignConfigs;

    // hasMinted(dummyID(signature) => bool) that records if the user account has already used the dummyID(signature).
    mapping(uint256 => bool) public hasMinted;

    mapping(bytes => bool) public usedSignatures;

    /* ============ Constructor ============ */
    constructor(
        address _owner,
        address _signer
    ) EIP712("GalxeTR", "1.0.0") {
        require(_owner != address(0), "Owner address must not be null address");
        owner = _owner;
        signer = _signer;

        emit EventOwnerUpdate(address(0), _owner);
        emit EventSignerUpdate(address(0), _signer);
    }

    /* ============ External Functions ============ */

    function activateCampaign(
        uint256 _cid,
        address _token,
        uint256 _amountPerAddress,
        uint256 _totalAddress,
        bytes calldata _signature
    ) external payable onlyNotPaused {
        require(_amountPerAddress > 0, "Amount per address must be greater than zero");
        require(_totalAddress > 0, "Address count must be greater than zero");
        require(campaignConfigs[_cid].admin == address(0), "Campaign has been activated");
        require(
            _verify(
                _hashActiveCampaign(_cid, msg.sender, _token, _amountPerAddress, _totalAddress),
                _signature
            ),
            "Invalid signature"
        );

        campaignConfigs[_cid] = CampaignConfig(
            msg.sender,
            _token,
            _amountPerAddress,
            uint128(_totalAddress),
            0
        );

        uint256 totalTokenAmount = _amountPerAddress.mul(_totalAddress);
        if (_token == address(0)) {
            // use native token
            require(msg.value == totalTokenAmount, "Activate campaign fail, not enough token");
        } else {
            // use erc20
            bool deposit = IERC20(_token).transferFrom(msg.sender, address(this), totalTokenAmount);
            require(deposit, "Activate campaign fail, not enough token");
        }

        emit EventActivateCampaign(_cid, msg.sender, _token, _amountPerAddress, _totalAddress);
    }

    function withdraw(uint256 _cid, bytes calldata _signature) external {
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.claimed < config.totalAddress, "No more token to withdraw");
        require(
            _verify(
                _hashWithdraw(_cid),
                _signature
            ),
            "Invalid signature"
        );

        uint256 balance = uint256(config.totalAddress-config.claimed).mul(config.amountPerAddress);
        config.claimed = config.totalAddress;

        if (config.token == address(0)) {
            (bool success, ) = config.admin.call{value: balance}(new bytes(0));
            require(success, "Transfer failed");
        } else {
            bool success = IERC20(config.token).transfer(config.admin, balance);
            require(success, "Transfer failed");
        }

        emit EventWithdraw(_cid, config.token, balance, config.admin);
    }

    function claim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _expiredAt,
        address payable _claimTo,
        bytes calldata _signature
    ) external onlyNotPaused {
        require(!hasMinted[_dummyId], "Already claimed");
        require(_expiredAt >= block.timestamp, "Signature expired");
        require(
            _verify(
                _hashClaim(_cid, _dummyId, _expiredAt, _claimTo),
                _signature
            ),
            "Invalid signature"
        );
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.claimed < config.totalAddress, "No more reward available");
        
        hasMinted[_dummyId] = true;
        config.claimed = config.claimed + 1;

        if (config.token == address(0)) {
            (bool success, ) = _claimTo.call{value: config.amountPerAddress}(new bytes(0));
            require(success, "Transfer failed");
        } else {
            bool success = IERC20(config.token).transfer(_claimTo, config.amountPerAddress);
            require(success, "Transfer failed");
        }

        emit EventClaim(_cid, config.token, config.amountPerAddress, _dummyId, _claimTo);
    }

    function updateCampaignAdmin(uint256 _cid, uint256 _salt, address _admin, bytes calldata _signature) external {
        require(_admin != address(0), "Invalid address");
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.admin == msg.sender, "Not the admin");
        require(!usedSignatures[_signature], "Invalid signature");
        require(
            _verify(
                _hashUpdateCampaignAdmin(_cid, _salt, config.admin, _admin),
                _signature
            ),
            "Invalid signature"
        );

        usedSignatures[_signature] = true;

        emit EventCampaignAdminUpdate(_cid, config.admin, _admin);
        config.admin = _admin;
    }

    function updateSigner(address _signer) external {
        require(msg.sender == owner, "Not the owner");
        require(_signer != address(0), "Invalid address");

        emit EventSignerUpdate(signer, _signer);
        signer = _signer;
    }

    function updateOwner(address _owner) external {
        require(msg.sender == owner, "Not the owner");
        require(owner != address(0), "Invalid address");

        emit EventOwnerUpdate(owner, _owner);
        owner = _owner;
    }

    function updatePaused(bool _paused) external {
        require(msg.sender == owner, "Not the owner");
        require(_paused != paused, "Invalid value");

        emit EventPausedUpdate(paused, _paused);
        paused = _paused;
    }

    receive() external payable {
        // anonymous transfer: to admin
        (bool success, ) = owner.call{value: msg.value}(
            new bytes(0)
        );
        require(success, "Transfer failed");
    }

    fallback() external payable {
        if (msg.value > 0) {
            // call non exist function: send to admin
            (bool success, ) = owner.call{value: msg.value}(new bytes(0));
            require(success, "Transfer failed");
        }
    }

    /* ============ Internal Functions ============ */
    function _hashActiveCampaign(
        uint256 _cid,
        address _admin,
        address _token,
        uint256 _amountPerAddress,
        uint256 _totalAddress
    ) private view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ActiveCampaign(uint256 cid,address admin,address token,uint256 amountPerAddress,uint256 totalAddress)"
                    ),
                    _cid,
                    _admin,
                    _token,
                    _amountPerAddress,
                    _totalAddress
                )
            )
        );
    }

    function _hashUpdateCampaignAdmin(
        uint256 _cid,
        uint256 _salt,
        address _oldAdmin,
        address _newAdmin
    ) private view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "UpdateCampaignAdmin(uint256 cid,uint256 salt,address oldAdmin,address newAdmin)"
                    ),
                    _cid,
                    _salt,
                    _oldAdmin,
                    _newAdmin
                )
            )
        );
    }

    function _hashWithdraw(
        uint256 _cid
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Withdraw(uint256 cid)"
                    ),
                    _cid
                )
            )
        );
    }

    function _hashClaim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _expiredAt,
        address _claimTo
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Claim(uint256 cid,uint256 dummyId,uint256 expiredAt,address claimTo)"
                    ),
                    _cid,
                    _dummyId,
                    _expiredAt,
                    _claimTo
                )
            )
        );
    }

    function _verify(bytes32 hash, bytes calldata signature)
    public // TODO
    view
    returns (bool)
    {
        return ECDSA.recover(hash, signature) == signer;
    }

    function _validateOnlyNotPaused() internal view {
        require(!paused, "Contract paused");
    }
}