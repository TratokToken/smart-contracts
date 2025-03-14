// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title TratokBatch
 * @dev This contract enables batch transfers of Tratok to multiple recipients in one transaction. The purpose for this is to cut down on delays when there are multiple transactions when the ecosystem grows.
 */
contract TratokBatch {
    /**
     * @dev Executes a batch transfer of Tratok tokens to multiple recipients.
     * @param recipients An array of addresses to receive the tokens.
     * @param amounts An array of token amounts corresponding to each recipient.
     * @notice The lengths of recipients and amounts arrays must be equal.
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        // Validate input arrays
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        require(recipients.length > 0, "At least one recipient is required");

        // Interface to interact with the ERC20 token contract
        address tokenAddress = 0x99d7a7F4C5551955c4bA5bA3C8965fFD9C869B4c; // Fixed: use address literal
        ERC20 erc20 = ERC20(tokenAddress);

        // Perform transfers in a loop
        for (uint256 i = 0; i < recipients.length; i++) {
            require(erc20.transferFrom(msg.sender, recipients[i], amounts[i]), "Token transfer failed");
        }
    }
}

/**
 * @dev Minimal ERC20 interface for interacting with the Tratok token for sending.
 */
interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
