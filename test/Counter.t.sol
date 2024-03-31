// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NftManager.sol";
import "../src/mock/ERC721Sample.sol";
import "../src/NftTemplate.sol";
import {NftManagerStorage} from "../src/NftManagerStorage.sol";
import "../src/NftURITemplate.sol";

contract CounterTest is Test {
    NftManager public nftManager;
    ERC721Sample public nft;
    NftTemplate public nftTemplate;
    NftURITemplate public nftURITemplate;

    address user1 = address(0x8C8D7C46219D9205f056f28fee5950aD564d7465);
    address authAdmin_ = address(0x077D360f11D220E4d5D831430c81C26c9be7C4A4);

    address operator = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);

    function setUp() public {
        vm.chainId(11155111);
        nftManager = new NftManager();
        nftManager.initialize();
        nft = new ERC721Sample();
        nftTemplate = new NftTemplate("NftTemplate", "NT", address(nftManager), authAdmin_);
        nftURITemplate = new NftURITemplate("NftTemplate", "NT", address(nftManager), authAdmin_);
    }

    function testIncrement() public {
        //        nft.mint(user1, "");
        //        vm.startPrank(user1);
        //        nftManager.approveInSrcChain(address(nft), 1, 2, true, 5);
        //
        //        NftManagerStorage.AuthData memory srcAuthData = NftManagerStorage.AuthData(address(nft), 1, 1, 2, true, 5);
        //        vm.chainId(2);
        //        bytes32 hash = nftManager.hashAuthData(srcAuthData, user1, 1);
        //        uint256 p = vm.envUint("DEPLOY_KEY");
        //        (uint8 v, bytes32 r, bytes32 s) = vm.sign(p, hash);
        //        nftManager.approveInToChain(srcAuthData, user1, 1, abi.encode(r, s, v));
        //        vm.stopPrank();
    }

    function testHashNftTemplate() public {
        vm.chainId(11155111);
        console.logBytes32(nftURITemplate.DOMAIN_SEPARATOR());
        console.logAddress(address(nft));
        console.logAddress(address(nftURITemplate));
        bytes32 hash2 = nftURITemplate.hashAuthMintData(authAdmin_, address(0), 1, address(nft), 1, 1, user1, 1, "");
        console.logBytes32(hash2);

        bytes32 hash3 = nftURITemplate.hashUpdateData( 1, "", 1);
        console.logBytes32(hash3);
    }

    function testHash() public {
//        console.log("nftManager:", address(nftManager));
//        console.log("nft:", address(nft));
//        console.logBytes32(nftManager.DOMAIN_SEPARATOR());
//        vm.chainId(11155111);
//        NftManagerStorage.AuthData memory srcAuthData = NftManagerStorage.AuthData(address(nft), 2, 80001, 11155111, true, 5);
//        //        bytes32 hash = nftManager._hashAuthData(srcAuthData);
//        //        console.logBytes32(hash);
//        bytes32 hash2 = nftManager.hashAuthData(srcAuthData, user1, 47579229);
//        console.logBytes32(hash2);
    }
}
