// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;


interface INftManager {
    function getFeeArgs(address srcNftAddr, uint256 srcTokenId, uint256 srcChainId) view external returns (address, uint32);

    function charge(address feeAsset, uint256 price, address srcNft, uint256 srcTokenId, uint256 srcChainId) external returns (bool);

    function register(address srcNft, uint256 srcTokenId, uint256 srcChainId) external returns (bool);

    function isAuthed(address requirer, address srcNft, uint256 srcTokenId, uint256 srcChainId) view external returns (bool);
}
