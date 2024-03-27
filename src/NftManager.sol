// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NftManagerStorage.sol";
import "./INftManager.sol";

contract NftManager is INftManager, NftManagerStorage {
    using SafeERC20 for IERC20;

    modifier checkNonce(uint256 nonce) {
        require(!_nonce[nonce], "NftManager: duplicate nonce");
        _nonce[nonce] = true;
        _;
    }

    modifier checkBlkHeight(uint256 expiredHeight) {
        require(block.number <= expiredHeight, "NftManager: sig expired");
        _;
    }

    event ApproveInSrcChain(
        address indexed nft,
        address indexed owner,
        uint256 tokenId,
        uint256 srcChainId,
        uint256 toChainId,
        address feeReceiver,
        bool authOpt,
        uint256 blkHeight
    );
    event ApproveInToChain(
        address indexed nft,
        uint256 tokenId,
        uint256 srcChainId,
        uint256 toChainId,
        address feeReceiver,
        bool authOpt
    );
    event ApproveLocal(
        address indexed nft,
        uint256 tokenId,
        address nftOwner,
        bool authOpt
    );

    event TransferWrapper(
        address nft,
        address from,
        address to,
        uint256 tokenId,
        uint256 blkHeight
    );
    event Claim(address nft, address owner, uint256 tokenId, uint256 blkHeight);
    event TransferOrClaim(
        address indexed nft,
        uint256 tokenId,
        uint256 srcChainId,
        uint256 toChainId,
        address feeReceiver
    );

    event AddSigner(address indexed addedAddress);
    event DeleteSigner(address indexed deletedAddress);

    event Register(
        address indexed srcNft,
        address indexed user,
        uint256 srcTokenId,
        uint256 srcChainId
    );
    event Unregister(
        address indexed srcNft,
        address indexed user,
        uint256 srcTokenId,
        uint256 srcChainId
    );

    function initialize() public initializer {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)), //version
                block.chainid,
                address(this)
            )
        );
        __Ownable_init(msg.sender);
    }

    // [src, target] Query cost information
    function getFeeArgs(
        address srcNftAddr,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public view returns (address, uint32) {
        AuthData memory data = authDatas[srcNftAddr][srcTokenId][srcChainId];
        if (srcChainId == block.chainid) {
            FeeReceiver memory feeR = feeReceiversInSrcChain[srcNftAddr][
                srcTokenId
            ];
            return (feeR.receiver, data.feeRatio);
        } else {
            FeeReceiver memory feeR = feeReceiversInToChain[srcNftAddr][
                srcTokenId
            ][srcChainId];
            return (feeR.receiver, data.feeRatio);
        }
    }

    // [target]
    function charge(
        address feeAsset,
        uint256 price,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) external returns (bool) {
        FeeReceiver memory feeR = feeReceiversInToChain[srcNft][srcTokenId][
            srcChainId
        ];
        require(
            feeR.receiver != address(0),
            "NftManager: charge invalid receiver"
        );
        AuthData memory data = authDatas[srcNft][srcTokenId][srcChainId];
        IERC20(feeAsset).safeTransferFrom(
            msg.sender,
            feeR.receiver,
            (price * data.feeRatio) / FeeFactor
        );
        return true;
    }

    // [target] register nft in target chain
    function register(
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) external returns (bool) {
        require(
            authStatus[getKey(msg.sender, srcNft, srcTokenId, srcChainId)] !=
                AuthStatus.Rejected,
            "NftManager: auth rejected"
        );
        authStatus[
            getKey(msg.sender, srcNft, srcTokenId, srcChainId)
        ] = AuthStatus.Authed;
        emit Register(srcNft, msg.sender, srcTokenId, srcChainId);
        return true;
    }

    // [target]
    function unregister(
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) external returns (bool) {
        require(
            authStatus[getKey(msg.sender, srcNft, srcTokenId, srcChainId)] !=
                AuthStatus.Rejected,
            "NftManager: auth rejected"
        );
        delete authStatus[getKey(msg.sender, srcNft, srcTokenId, srcChainId)];
        emit Unregister(srcNft, msg.sender, srcTokenId, srcChainId);
        return true;
    }

    //todo
    // [target]
    function isAuthed(
        address requirer,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public view returns (bool) {
        return
            authDatas[srcNft][srcTokenId][srcChainId].authOpt &&
            (authStatus[getKey(requirer, srcNft, srcTokenId, srcChainId)] ==
                AuthStatus.Authed);
    }

    // target
    //0 unauthed 1 authed 2 black
    //todo  authedNft; // auth[requirer][nft][tokenid][chainid]=true
    // [target]
    function addBlackList(
        address user,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public returns (bool) {
        FeeReceiver memory f = feeReceiversInToChain[srcNft][srcTokenId][
            srcChainId
        ];
        require(f.receiver == msg.sender, "NftManager: invalid nftOwner");
        authStatus[getKey(user, srcNft, srcTokenId, srcChainId)] = AuthStatus
            .Rejected;
        return true;
    }
    // [target]
    function removeBlackList(
        address user,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public returns (bool) {
        FeeReceiver memory f = feeReceiversInToChain[srcNft][srcTokenId][
            srcChainId
        ];
        require(f.receiver == msg.sender, "NftManager: invalid nftOwner");
        authStatus[getKey(user, srcNft, srcTokenId, srcChainId)] = AuthStatus
            .Authed;
        return true;
    }
    // [target]
    function getAuthStatus(
        address user,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public view returns (AuthStatus) {
        return authStatus[getKey(user, srcNft, srcTokenId, srcChainId)];
    }

    function getKey(
        address user,
        address nft,
        uint256 tokenId,
        uint256 toChainId
    ) internal pure returns (bytes32) {
        bytes memory data = abi.encode(user, nft, tokenId, toChainId);
        return keccak256(data);
    }

    // [src] execute in src chain
    function approveInSrcChain(
        address nft,
        uint256 tokenId,
        uint256 toChainId,
        bool authOpt,
        uint32 feeRatio
    ) public {
        require(toChainId != block.chainid, "NftManager: invalid toChainId");
        address nftOwner = IERC721(nft).ownerOf(tokenId);
        require(msg.sender == nftOwner, "NftManager: invalid nft owner");
        require(feeRatio < FeeFactor, "NftManager: feeRatio too high");
        authDatas[nft][tokenId][toChainId] = AuthData(
            nft,
            tokenId,
            block.chainid,
            toChainId,
            authOpt,
            feeRatio
        );
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(
            msg.sender,
            block.number
        );
        emit ApproveInSrcChain(
            nft,
            msg.sender,
            tokenId,
            block.chainid,
            toChainId,
            nftOwner,
            authOpt,
            block.number
        );
    }

    // [src] src chain
    function transferWrapper(address nft, uint256 tokenId, address to) public {
        IERC721(nft).safeTransferFrom(msg.sender, to, tokenId, new bytes(0));
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(to, block.number);
        emit TransferWrapper(nft, msg.sender, to, tokenId, block.number);
    }

    // [src == target]
    function transferWrapperLocal(
        address nft,
        uint256 tokenId,
        address to
    ) public {
        IERC721(nft).safeTransferFrom(msg.sender, to, tokenId, new bytes(0));
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(to, block.number);
        feeReceiversInToChain[nft][tokenId][block.chainid] = FeeReceiver(
            to,
            block.number
        );
        emit TransferWrapper(nft, msg.sender, to, tokenId, block.number);
    }

    // [src] src chain
    function claim(address nft, uint256 tokenId) public {
        address nftOwner = IERC721(nft).ownerOf(tokenId);
        require(msg.sender == nftOwner, "NftManager: invalid nft owner");
        require(
            msg.sender != feeReceiversInSrcChain[nft][tokenId].receiver,
            "NftManager: invalid fee receiver"
        );
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(
            nftOwner,
            block.number
        );
        emit Claim(nft, nftOwner, tokenId, block.number);
    }

    // [src == target]
    function claimLocal(address nft, uint256 tokenId) public {
        address nftOwner = IERC721(nft).ownerOf(tokenId);
        require(msg.sender == nftOwner, "NftManager: invalid nft owner");
        require(
            msg.sender != feeReceiversInSrcChain[nft][tokenId].receiver,
            "NftManager: invalid fee receiver"
        );
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(
            nftOwner,
            block.number
        );
        feeReceiversInToChain[nft][tokenId][block.chainid] = FeeReceiver(
            nftOwner,
            block.number
        );
        emit Claim(nft, nftOwner, tokenId, block.number);
    }

    // [target] target chain, use source blockheight to avoid double spend
    function transferOrClaim(
        AuthData calldata srcAuthData,
        address feeReceiver,
        uint256 srcHeight,
        bytes calldata sigs
    ) public {
        require(
            srcAuthData.toChainId == block.chainid,
            "NftManager: invalid toChainId"
        );
        require(feeReceiver == msg.sender, "NftManager: invalid feeReceiver");
        bytes32 hash = hashAuthData(srcAuthData, feeReceiver, srcHeight);
        require(_checkInSigs(hash, sigs), "NftManager: invalid signer");
        feeReceiversInToChain[srcAuthData.nft][srcAuthData.tokenId][
            srcAuthData.srcChainId
        ] = FeeReceiver(feeReceiver, block.number);
        emit TransferOrClaim(
            srcAuthData.nft,
            srcAuthData.tokenId,
            srcAuthData.srcChainId,
            srcAuthData.toChainId,
            feeReceiver
        );
    }

    // [target] execute in target chain
    function approveInToChain(
        AuthData calldata srcAuthData,
        address feeReceiver,
        uint256 height,
        bytes calldata sigs
    ) public {
        require(
            srcAuthData.toChainId == block.chainid,
            "NftManager: invalid toChainId"
        );
        require(msg.sender == feeReceiver, "NftManager: invalid feeReceiver");
        require(
            height >
                feeReceiversInToChain[srcAuthData.nft][srcAuthData.tokenId][
                    srcAuthData.srcChainId
                ].height,
            "NftManager: height check failed"
        );
        bytes32 hash = hashAuthData(srcAuthData, feeReceiver, height);
        require(_checkInSigs(hash, sigs), "NftManager: invalid signer");
        authDatas[srcAuthData.nft][srcAuthData.tokenId][
            srcAuthData.srcChainId
        ] = srcAuthData;
        feeReceiversInToChain[srcAuthData.nft][srcAuthData.tokenId][
            srcAuthData.srcChainId
        ] = FeeReceiver(feeReceiver, height);
        emit ApproveInToChain(
            srcAuthData.nft,
            srcAuthData.tokenId,
            srcAuthData.srcChainId,
            srcAuthData.toChainId,
            feeReceiver,
            srcAuthData.authOpt
        );
    }

    // [src == target] mono chain approve
    function approveLocal(
        address nft,
        uint256 tokenId,
        bool authOpt,
        uint32 feeRatio
    ) public {
        address nftOwner = IERC721(nft).ownerOf(tokenId);
        require(msg.sender == nftOwner, "NftManager: invalid nft owner");
        authDatas[nft][tokenId][block.chainid] = AuthData(
            nft,
            tokenId,
            block.chainid,
            block.chainid,
            authOpt,
            feeRatio
        );
        feeReceiversInSrcChain[nft][tokenId] = FeeReceiver(
            msg.sender,
            block.number
        );
        feeReceiversInToChain[nft][tokenId][block.chainid] = FeeReceiver(
            msg.sender,
            block.number
        );
        emit ApproveLocal(nft, tokenId, nftOwner, authOpt);
    }

    function addSigner(address newSigner) public onlyOwner {
        require(!_signers[newSigner], "NftManager: signer added");
        _signers[newSigner] = true;
        emit AddSigner(newSigner);
    }

    function deleteSigner(address deletedSigner) public onlyOwner {
        require(_signers[deletedSigner], "NftManager: invalid signer");
        delete (_signers[deletedSigner]);
        emit DeleteSigner(deletedSigner);
    }

    function _checkInSigs(
        bytes32 message,
        bytes calldata sigs
    ) internal view returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sigs);
        address signer = ecrecover(message, v, r, s);
        return _signers[signer];
    }

    function hashAuthData(
        AuthData calldata srcAuthData,
        address feeReceiver,
        uint256 height
    ) public view returns (bytes32) {
        //ERC-712
        bytes32 srcAuthDataHash = _hashAuthData(srcAuthData);
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "authData(AuthData srcAuthData,address feeReceiver,uint256 height)AuthData(address nft,uint256 tokenId,uint256 srcChainId,uint256 toChainId,bool authOpt,uint256 feeRatio)"
                            ),
                            keccak256(abi.encodePacked(srcAuthDataHash)),
                            feeReceiver,
                            height
                        )
                    )
                )
            );
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(
                            "authData(AuthData srcAuthData,address feeReceiver,uint256 height)AuthData(address nft,uint256 tokenId,uint256 toChainId,bool authOpt,uint256 feeRatio)"
                        ),
                        keccak256(abi.encodePacked(srcAuthDataHash)),
                        feeReceiver,
                        height
                    )
                )
            )
        );
    }

    function _hashAuthData(
        AuthData calldata srcAuthData
    ) internal pure returns (bytes32) {
        //ERC-712
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "AuthData(address nft,uint256 tokenId,uint256 toChainId,bool authOpt,uint256 feeRatio)"
                    ),
                    srcAuthData.nft,
                    srcAuthData.tokenId,
                    srcAuthData.toChainId,
                    srcAuthData.authOpt,
                    srcAuthData.feeRatio
                )
            );
    }

    // signature methods.
    function _splitSignature(
        bytes memory sig
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}
