// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

"@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract OctiPaymentSplitter is PaymentSplitter {
   
    /**
    * @dev Contract constructor.
    * @param royaltyAddress Address to send contract-level royalties.
    * @param _contractURI String representing RFC 3986 URI.
    */
    constructor(address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable { }

}