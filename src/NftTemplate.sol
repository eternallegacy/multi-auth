// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./INftManager.sol";

contract NftTemplate is ERC721 {
    INftManager internal nftManager;
    address internal authAdmin;
    uint256 internal curId;
    mapping(uint256 => bool) internal nonces;

    mapping(address => bool) internal _signers; // signer=>bool

    string public constant nameSig = "NftTemplate";
    string public constant version = "1.0";
    bytes32 public DOMAIN_SEPARATOR;

    struct AuthedInfo {
        address srcNft;
        uint256 srcTokenId;
        uint256 srcChainId;
    }

    mapping(uint256 => AuthedInfo) public authedInfos;

    modifier onlyNonce(uint256 nonce) {
        require(nonces[nonce] == false, "NftTemplate: duplicate nonce");
        nonces[nonce] = true;
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address nftManager_,
        address authAdmin_
    ) ERC721(name_, symbol_) {
        nftManager = INftManager(nftManager_);
        authAdmin = authAdmin_;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(nameSig)),
                keccak256(bytes(version)), //version
                block.chainid,
                address(this)
            )
        );
    }


    function getAuthAdmin() public view returns (address) {
        return authAdmin;
    }

    function getNftManager() view public returns (address) {
        return address(nftManager);
    }

    function mintWithAuth(
        address to,
        address feeToken,
        uint256 price,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId
    ) public {
        //todo
        require(
            nftManager.isAuthed(msg.sender, srcNft, srcTokenId, srcChainId),
            "NftTemplate: unauthed"
        );
        (address _receiver, uint32 feeRatio) = nftManager.getFeeArgs(
            srcNft,
            srcTokenId,
            srcChainId
        );
        IERC20(feeToken).transferFrom(msg.sender, address(this), price);
        IERC20(feeToken).approve(
            address(nftManager),
            (price * feeRatio) / 10000
        );
        nftManager.charge(feeToken, price, srcNft, srcTokenId, srcChainId);
        uint256 tokenId = getNextTokenId();
        _safeMint(to, tokenId);
        authedInfos[tokenId] = AuthedInfo(srcNft, srcTokenId, srcChainId);
    }

    function getNextTokenId() internal returns (uint256) {
        curId = curId + 1;
        return curId;
    }

    function mintWithSig(
        address authedSigner,
        address feeToken,
        uint256 price,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId,
        uint256 nonce,
        bytes calldata sig
    ) public onlyNonce(nonce) {
        require(
            nftManager.isAuthed(authedSigner, srcNft, srcTokenId, srcChainId),
            "NftTemplate: unAuthed"
        );
        uint256 tokenId = getNextTokenId();
        bytes32 hash = hashAuthData(authedSigner, feeToken, price, srcNft, srcTokenId, srcChainId, msg.sender, nonce);
        require(_checkInSigs(hash, sig, authedSigner), "NftTemplate: invalid signature");
        //todo
        (address _receiver, uint32 feeRatio) = nftManager.getFeeArgs(
            srcNft,
            srcTokenId,
            srcChainId
        );
        IERC20(feeToken).transferFrom(msg.sender, address(this), price);
        IERC20(feeToken).approve(
            address(nftManager),
            (price * feeRatio) / 10000
        );
        nftManager.charge(feeToken, price, srcNft, srcTokenId, srcChainId);
        _safeMint(msg.sender, tokenId);
        authedInfos[tokenId] = AuthedInfo(srcNft, srcTokenId, srcChainId);
    }

    function _checkInSigs(
        bytes32 message,
        bytes calldata sigs,
        address authedSigner
    ) internal view returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sigs);
        address signer = ecrecover(message, v, r, s);
        return authedSigner == signer;
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

    function hashAuthData(
        address authedSigner,
        address feeToken,
        uint256 price,
        address srcNft,
        uint256 srcTokenId,
        uint256 srcChainId,
        address to,
        uint256 nonce
    ) public view returns (bytes32) {
        //ERC-712
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256("authData(address authedSigner,address feeToken, uint256 price, address srcNft, uint256 srcTokenId, uint256 srcChainId, address to,uint256 nonce)"),
                        authedSigner, feeToken, price, srcNft, srcTokenId, srcChainId, to, nonce
                    )
                )
            )
        );
    }
}
