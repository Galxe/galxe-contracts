/*
    Copyright 2021 Project Galaxy.

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

import "@openzeppelin-v3/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-v3/contracts/access/Ownable.sol";
import "@openzeppelin-v3/contracts/cryptography/MerkleProof.sol";
import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    // using SafeERC20 for IERC20;
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public endBlock;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, uint256 endBlock_) public {
        require(token_ != address(0), 'Invalid token address');
        token = token_;
        merkleRoot = merkleRoot_;
        endBlock = endBlock_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function withdrawRemaining(address recipient, uint256 amount) external onlyOwner {
        // IERC20(token).safeTransfer(recipient, amount);
        require(block.number > endBlock, 'Deadline not reached!');
        require(IERC20(token).transfer(recipient, amount), 'Withdraw remaining failed.');
    }
}
