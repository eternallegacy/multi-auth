// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NftManager.sol";
import "../src/NftManagerProxy.sol";
import "../src/NftTemplate.sol";
import "../src/mock/ERC721Sample.sol";
import "../src/NftManagerStorage.sol";

//nftManagerProxy    0x0dc57b0cc323f418aa2107095d8e34c3c88004d0
//NftTemplate     0x5a074f4c99853700131858d66de22fe3a6b50186
//ERC721Sample    0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B
//forge script script/NftManagerSepolia.s.sol:NftManagerScriptSepolia --legacy --broadcast --rpc-url $SEPOLIA --via-ir
contract NftManagerScriptSepolia is Script {
    function setUp() public {}

    function run() public {
        uint256 upgradePrivateKey = vm.envUint("UPGRADE_KEY");
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_KEY");
        address deployerAddress = vm.envAddress("DEPLOY_ADDRESS");
        address UPGRADE_ADDRESS = vm.envAddress("UPGRADE_ADDRESS");
        if (true) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            bytes memory data = abi.encodeWithSelector(NftManager.initialize.selector);
            NftManagerProxy nftManagerProxy = new NftManagerProxy(address(nftManager), UPGRADE_ADDRESS, data);
            NftTemplate nftTemplate = new NftTemplate("NftTemplate", "NT", address(nftManagerProxy), deployerAddress);
            vm.stopBroadcast();
            return;
        }
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            vm.stopBroadcast();
            vm.startBroadcast(upgradePrivateKey);
            NftManagerProxy nftManagerProxy = NftManagerProxy(payable(address(0x1Aa95735855C012130D76A7C736B0C464366C92c)));
            //            nftManagerProxy.upgradeToAndCall(address(nftManager), new bytes(0));
            vm.stopBroadcast();
            return;
        }
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            ERC721Sample srcNft = new ERC721Sample();
            console.log("srcNft:", address(srcNft));
            //            NftManager nftManager = NftManager(0xb3a143ee2f41033e3f3c7f69da11e068eda6f90d);
            //            NftManagerProxy nftManagerProxy = NftManagerProxy(0x1aa95735855c012130d76a7c736b0c464366c92c);
            //            NftTemplate nftTemplate = NftTemplate(0x5a074f4c99853700131858d66de22fe3a6b50186);
            vm.stopBroadcast();
            return;
        }
        if (true) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            ERC721Sample srcNft = ERC721Sample(0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B);
            //            srcNft.mint(deployerAddress, "");
            console.log("srcNft:", address(srcNft));
            NftManager nftManager = NftManager(0x0DC57b0cC323f418aa2107095d8E34c3C88004D0);
            NftManagerStorage.AuthData memory srcAuthData = NftManagerStorage.AuthData(address(srcNft), 2, 80001, 11155111, true, 5);
            bytes32 hash = nftManager.hashAuthData(srcAuthData, deployerAddress, 47579229);
            console.logBytes32(hash);
            //sepolia chainid
            //            nftManager.approveInToChain(address(srcNft), 2, 11155111, true, 5);
            vm.stopBroadcast();
            return;
        }
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            ERC721Sample srcNft = ERC721Sample(0x1c5Dd239a7c7e524A7491cc34FA978779dC20452);
            srcNft.mint(deployerAddress, "");
            console.log("srcNft:", address(srcNft));
            NftManager nftManager = NftManager(0x1Aa95735855C012130D76A7C736B0C464366C92c);
            //sepolia chainid
            nftManager.approveInSrcChain(address(srcNft), 2, 11155111, true, 5);
            vm.stopBroadcast();
        }
    }
}
