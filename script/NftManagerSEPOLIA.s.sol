// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NftManager.sol";
import "../src/NftManagerProxy.sol";

//forge script script/NftManagerSEPOLIA.s.sol:NftManagerScript --legacy --broadcast --rpc-url $SEPOLIA --via-ir
contract NftManagerScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_KEY");
        address UPGRADE_ADDRESS = vm.envAddress("UPGRADE_ADDRESS");
        if (true) {
            vm.startBroadcast(deployerPrivateKey);
            NftManager nftManager = new NftManager();
            bytes memory data = abi.encodeWithSelector(NftManager.initialize.selector);
            NftManagerProxy nftManagerProxy = new NftManagerProxy(address(nftManager), UPGRADE_ADDRESS, data);
        }
        vm.broadcast();
    }
}
