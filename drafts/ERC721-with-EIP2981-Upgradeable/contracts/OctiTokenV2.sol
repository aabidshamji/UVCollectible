// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./OctiToken.sol";

contract OctiTokenV2 is OctiToken {
    function getVersion() external pure returns(string memory){
        string memory version = "This is version 2";
        return version;
    }

}