// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IStarNFT} from "./IStarNFT.sol";

/**
 * @title IStarNFT
 * @author Galaxy Protocol
 *
 * Interface for operating with StarNFTs.
 */
interface ISpaceStation {

    function claim(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        address _mintTo,
        bytes calldata _signature
    ) external payable;

    function claimBatch(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        address _mintTo,
        bytes calldata _signature
    ) external payable;

    function claimCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        uint256 _cap,
        address _mintTo,
        bytes calldata _signature
    ) external payable;

    function claimBatchCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        uint256 _cap,
        address _mintTo,
        bytes calldata _signature
    ) external payable;

    function forge(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _nftIDs,
        uint256 _dummyId,
        uint256 _powah,
        address _mintTo,
        bytes calldata _signature
    ) external payable;
}
