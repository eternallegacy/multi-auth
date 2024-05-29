// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

abstract contract NftManagerStorage is OwnableUpgradeable {
    struct AuthData {
        address nft;
        uint256 tokenId;
        uint256 srcChainId;
        uint256 toChainId;
        bool authOpt;
        uint256 feeRatio;
    }

    // [src, target]
    struct FeeReceiver {
        address receiver;
        uint256 height;
    }

    // [target]
    enum AuthStatus {
        UnAuth,
        Authed,
        Rejected
    }

    uint256 constant FeeFactor = 10000;

    // [target]
    mapping(bytes32 => AuthStatus) internal authStatus; // auth[requirer][nft][tokenid][chainid]=true

    // [src, target]
    mapping(address => mapping(uint256 => mapping(uint256 => AuthData)))
        public authDatas; // nft=>tokenId=>chainId=>AuthData
    // [src]
    mapping(address => mapping(uint256 => FeeReceiver))
        public feeReceiversInSrcChain; // nft=>tokenId => receiver
    // [target]
    mapping(address => mapping(uint256 => mapping(uint256 => FeeReceiver)))
        internal feeReceiversInToChain; // [nft][tokenId][srcChainId] = nftOwner;

    mapping(address => bool) internal _signers; // signer=>bool
    mapping(uint256 => bool) internal _nonce; // for nonce that has already used

    string public constant name = "NftManager";
    string public constant version = "1.0";
    bytes32 public DOMAIN_SEPARATOR;
}
