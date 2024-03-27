// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NftManager.sol";
import "../src/mock/ERC721Sample.sol";
import "../src/NftTemplate.sol";
import {NftManagerStorage} from "../src/NftManagerStorage.sol";

contract CounterTest is Test {
    NftManager public nftManager;
    ERC721Sample public nft;
    NftTemplate public nftTemplate;

    address user1 = address(0x8C8D7C46219D9205f056f28fee5950aD564d7465);
    address user2 = address(0x077D360f11D220E4d5D831430c81C26c9be7C4A4);

    address operator = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);

    function setUp() public {

        nftManager = new NftManager();
        nft = new ERC721Sample();
        nftTemplate = new NftTemplate("nftTemplaet", "NT", address(nftManager), msg.sender);
    }

    function testIncrement() public {
        nft.mint(user1, "");
        vm.startPrank(user1);
        nftManager.approveInSrcChain(address(nft), 1, 2, true, 5);

        NftManagerStorage.AuthData memory srcAuthData = NftManagerStorage.AuthData(address(nft), 1, 1, 2, true, 5);
        vm.chainId(2);
        bytes32 hash = nftManager.hashAuthData(srcAuthData, user1, 1);
        uint256 p = vm.envUint("DEPLOY_KEY");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(p, hash);
        nftManager.approveInToChain(srcAuthData, user1, 1, abi.encode(r, s, v));
        vm.stopPrank();
    }
}
