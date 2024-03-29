// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NftManager.sol";
import "../src/NftManagerProxy.sol";
import "../src/NftTemplate.sol";
import "../src/mock/ERC721Sample.sol";

//ProxyAdmin 0xAB431b96EA3Ab39035c5B7C6cF6daC001e702a57
//nftManagerProxy  0xc9a97e05e0e2f08f778f31bbe2a89067988a160c
//NftTemplate     0x6000aa2c4bda0d41d0ab1865e26b6bba22cf1615
//ERC721Sample    0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B
//forge script script/NftManagerMubai.s.sol:NftManagerScript --legacy --broadcast --rpc-url $POLYGON_MUBAI --via-ir
contract NftManagerScript is Script {

    address nftManagerProxy;
    NftManager nftManager;
    ERC721Sample srcNft;

    function setUp() public {
        nftManagerProxy = address(0xC9a97E05E0E2F08f778F31bBE2a89067988a160c);
        nftManager = NftManager(nftManagerProxy);
        srcNft = ERC721Sample(0x501FD84bcF9f431778d62fBb1B55a5B07ddF2F6B);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_KEY");
        address deployerAddress = vm.envAddress("DEPLOY_ADDRESS");
        uint256 upgradePrivateKey = vm.envUint("UPGRADE_KEY");
        address UPGRADE_ADDRESS = vm.envAddress("UPGRADE_ADDRESS");
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            bytes memory data = abi.encodeWithSelector(NftManager.initialize.selector);
            NftManagerProxy nftManagerProxy = new NftManagerProxy(address(nftManager), UPGRADE_ADDRESS, data);
            //            NftTemplate nftTemplate = new NftTemplate("nft template", "NT", address(nftManagerProxy), deployerAddress);
            vm.stopBroadcast();
            return;
        }
        //upgrade
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            vm.stopBroadcast();
            vm.startBroadcast(upgradePrivateKey);
            address nftManagerProxy = address(0x1Aa95735855C012130D76A7C736B0C464366C92c);
            bytes memory dataParams = abi.encodeWithSelector(ITransparentUpgradeableProxy.upgradeToAndCall.selector,
                address(nftManager), new bytes(0));
            (bool success, bytes memory data) = payable(address(nftManagerProxy)).call(dataParams);
            vm.stopBroadcast();
            return;
        }
        if (true) {
            vm.startBroadcast(deployerPrivateKey);
            NftTemplate nftTemplate = new NftTemplate("NftTemplate", "NT", address(nftManager), deployerAddress);
            vm.stopBroadcast();
            return;
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
            return;
        }
        if (false) {
            vm.startBroadcast(deployerPrivateKey);
            //0x501fd84bcf9f431778d62fbb1b55a5b07ddf2f6b
            srcNft.mint(deployerAddress, "");
            console.log("srcNft:", address(srcNft));
            //sepolia chainid
            nftManager.approveInSrcChain(address(srcNft), 2, 11155111, true, 5);
            vm.stopBroadcast();
            return;
        }
    }
}
