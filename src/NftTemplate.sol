// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./INftManager.sol";

contract NftTemplate is ERC721 {
    INftManager internal nftManager;
    address internal authAdmin;

    constructor(string memory name_, string memory symbol_, address nftManager_, address authAdmin_)ERC721(name_, symbol_) {
        nftManager = INftManager(nftManager_);
        authAdmin = authAdmin_;
    }

    function getAuthAdmin() view public returns (address) {
        return authAdmin;
    }

    function getNftManager() view public returns (address) {
        return nftManager;
    }

    function mintWithAuth(address to, uint256 tokenId, address feeToken, uint256 price, address srcNft, uint256 srcTokenId, uint256 srcChainId) public {
        //todo
        require(nftManager.isAuthed(msg.sender, srcNft, srcTokenId, srcChainId), "NftTemplate: unauthed");
        (address _receiver,uint32 feeRatio) = nftManager.getFeeArgs(srcNft, srcTokenId, srcChainId);
        IERC20(feeToken).transferFrom(msg.sender, address(this), price);
        IERC20(feeToken).approve(address(nftManager), price * feeRatio / 10000);
        nftManager.charge(feeToken, price, srcNft, srcTokenId, srcChainId);
        _safeMint(to, tokenId);
    }

}
