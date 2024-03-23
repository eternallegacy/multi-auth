// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

abstract contract NftManagerStorage is OwnableUpgradeable {
    struct SrcNftData {
        address nft;
        uint256 tokenId;//decimals is 4
    }

    enum AuthStatus{
        UnAuth,
        Authed,
        Rejected
    }

    uint32 constant FeeFactor = 10000;
    mapping(bytes32 => AuthStatus) internal authStatus;// auth[requirer][nft][tokenid][chainid]=true

    struct AuthData {
        address nft;
        uint256 tokenId;
        uint256 srcChainId;
        uint256 toChainId;
        bool authOpt;
        uint32 feeRatio;
    }

    struct FeeReceiver {
        address receiver;
        uint256 height;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => AuthData))) internal authDatas;// nft=>tokenId=>AuthData
    mapping(address => mapping(uint256 => FeeReceiver)) internal feeReceiversInSrcChain;// nft=>tokenId => receiver
    mapping(address => mapping(uint256 => mapping(uint256 => FeeReceiver))) internal feeReceiversInToChain;// [nft][tokenId][srcChainId] = nftOwner;

    mapping(address => mapping(uint256 => mapping(uint256 => address[]))) internal authedAddressList;//[nft][tokenId][srcChainId] => address[]

    mapping(address => bool) internal _signers;// signer=>bool
    mapping(uint256 => bool) internal _nonce; // for nonce that has already used

    string public constant name = "NftManager";
    string public constant version = "1.0";
    bytes32 public DOMAIN_SEPARATOR;
}
