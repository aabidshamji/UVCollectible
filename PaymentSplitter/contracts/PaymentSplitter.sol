// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract OctiPaymentSplitter is PaymentSplitter {
   
    /**
    * @dev Contract constructor.
    * @param _payees List of addresses to be eligible for withdrawal
    * @param _shares Shares assigned to each address
    */
    constructor(address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable { }

}