// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    function test(bytes memory _walletAddress) public pure returns(address addr) {
        assembly {
        addr := mload(add(_walletAddress, 20))
    }
        // return address(uint160(bytes20(_walletAddress)));
    }
}