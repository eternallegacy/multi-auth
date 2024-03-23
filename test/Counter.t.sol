// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NftManager.sol";

contract CounterTest is Test {
    NftManager public counter;

    function setUp() public {
        counter = new NftManager();
    }

    function testIncrement() public {

    }

    function testSetNumber(uint256 x) public {

    }
}
