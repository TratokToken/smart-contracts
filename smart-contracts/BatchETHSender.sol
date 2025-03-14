// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchETHSender is Ownable {
    // Event to log successful transfers
    event TransferBatch(
        address indexed sender,
        address[] recipients,
        uint256 amountPerRecipient,
        uint256 timestamp
    );
    
    // Event to log failed transfers
    event TransferFailed(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    
    // Fallback function to accept ETH
    receive() external payable { }
    
    // Constructor sets the deployer as the owner
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Batch transfer same amount of ETH to multiple addresses
     * @param recipients Array of recipient addresses
     * @param amountPerRecipient Amount to send to each recipient (in wei)
     */
    function batchSendETH(
        address[] calldata recipients,
        uint256 amountPerRecipient
    ) external payable onlyOwner returns (bool) {
        // Input validation
        require(recipients.length > 0, "No recipients provided");
        require(amountPerRecipient > 0, "Amount must be greater than 0");
        
        // Calculate total required amount
        uint256 totalRequired = amountPerRecipient * recipients.length;
        require(msg.value >= totalRequired, "Insufficient ETH sent");
        
        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
        }
        
        // Process transfers
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            
            if (!success) {
                emit TransferFailed(recipients[i], amountPerRecipient, block.timestamp);
            }
        }
        
        // Emit successful batch transfer event
        emit TransferBatch(msg.sender, recipients, amountPerRecipient, block.timestamp);
        
        // Refund any excess ETH sent
        if (msg.value > totalRequired) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - totalRequired}("");
            require(refundSuccess, "Refund failed");
        }
        
        return true;
    }
    
    /**
     * @dev Get contract's current balance
     * @return Current ETH balance in wei
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdrawal function for stuck ETH
     * Only owner can withdraw
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    // Allow owner to transfer ETH directly to the contract if needed
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "No ETH sent");
    }
}
