/*
    Copyright 2022 Project Galaxy.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache 2.0
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract GAL is ERC20, ERC20Permit, Ownable {

    /// @notice Total number of tokens in circulation
    uint public TOTAL_SUPPLY = 200_000_000e18; // 200M GAL

    constructor(address _owner, address account) ERC20("Project Galaxy", "GAL") ERC20Permit("Project Galaxy") {
        transferOwnership(_owner);
        _mint(account, TOTAL_SUPPLY);
    }

    function mint(address account, uint amount) external onlyOwner {
        _mint(account, amount);
    }

}
