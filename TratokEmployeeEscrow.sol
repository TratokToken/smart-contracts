// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TratokEmployeeEscrow {
    struct Escrow {
        address deliveryAddress;
        uint256 releaseTime;
        uint256 amount;
        bool released;
    }

    IERC20 public token;
    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;
   
    constructor() {
        token = IERC20(0x35bC519E9fe5F04053079e8a0BF2a876D95D2B33);
    }

    function deposit(address _deliveryAddress, uint256 _days, uint256 _amount) external {
	
		// Ensure the amount is greater than zero
        require(_amount > 0, "Amount must be greater than 0");
		
		// Ensure the deposit has been successful
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

		// Create the escrow
        escrows[escrowCount] = Escrow({
            deliveryAddress: _deliveryAddress,
            releaseTime: block.timestamp + (_days * 1 days),
            amount: _amount,
            released: false
        });

		// Add additional escrow count
        escrowCount++;
    }

    function release(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
		
		// Ensure escrow has not already been released
        require(!escrow.released, "Tokens already released");
		
		// Ensure escrow time hold has passed
        require(block.timestamp >= escrow.releaseTime, "Tokens are still locked");
		
		// Ensure that sufficient tokens exist for the release
        require(escrow.amount > 0, "No tokens to release");

        // Transfer the tokens first
        require(token.transfer(escrow.deliveryAddress, escrow.amount), "Transfer failed");
        
        // Mark as released only after the transfer is successful
        escrow.released = true; 
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getEscrowDetails(uint256 escrowId) external view returns (address, uint256, uint256, bool) {
        Escrow storage escrow = escrows[escrowId];
        return (escrow.deliveryAddress, escrow.releaseTime, escrow.amount, escrow.released);
    }
}