// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NftManager.sol";
import "../src/NftManagerProxy.sol";
import "../src/NftTemplate.sol";
import "../src/mock/ERC721Sample.sol";

//nftManagerProxy  0x1aa95735855c012130d76a7c736b0c464366c92c
//NftTemplate     0x5a074f4c99853700131858d66de22fe3a6b50186
//ERC721Sample    0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B
//forge script script/NftManagerMubai.s.sol:NftManagerScript --legacy --broadcast --rpc-url $POLYGON_MUBAI --via-ir
contract NftManagerScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_KEY");
        address deployerAddress = vm.envAddress("DEPLOY_ADDRESS");
        address UPGRADE_ADDRESS = vm.envAddress("UPGRADE_ADDRESS");
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            bytes memory data = abi.encodeWithSelector(NftManager.initialize.selector);
            NftManagerProxy nftManagerProxy = new NftManagerProxy(address(nftManager), UPGRADE_ADDRESS, data);
            NftTemplate nftTemplate = new NftTemplate("nft template", "NT", address(nftManagerProxy), deployerAddress);
            vm.stopBroadcast();
        }
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            ERC721Sample srcNft = ERC721Sample(0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B);
            console.log("srcNft:", address(srcNft));
            //            NftManager nftManager = NftManager(0xb3a143ee2f41033e3f3c7f69da11e068eda6f90d);
            //            NftManagerProxy nftManagerProxy = NftManagerProxy(0x1aa95735855c012130d76a7c736b0c464366c92c);
            //            NftTemplate nftTemplate = NftTemplate(0x5a074f4c99853700131858d66de22fe3a6b50186);
            vm.stopBroadcast();
        }
        if (true) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            ERC721Sample srcNft = ERC721Sample(0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B);
            srcNft.mint(deployerAddress, "");
            console.log("srcNft:", address(srcNft));
            NftManager nftManager = NftManager(0x1Aa95735855C012130D76A7C736B0C464366C92c);
            //sepolia chainid
            nftManager.approveInSrcChain(address(srcNft), 2, 11155111, true, 5);
            vm.stopBroadcast();
        }
    }
}
