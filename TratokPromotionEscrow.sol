/*
SPDX-License-Identifier: MIT

This is the escrow smart contract for Tratok Promotion Program Participants.
This immutable contract allows the public to see to keep a track of rewards distributed as well as provide verification and guarantees of receiving their awards in good faith.

@version "1.0"
@developer "Tratok Team"
@date "19 December 2024"
@thoughts "Once a Tratokian always a Tratokian!" 
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PromotionEscrow {
    struct Escrow {
        address deliveryAddress;
        uint256 releaseTime;
        uint256 amount;
        bool released;
    }

    IERC20 public token;
    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;
    uint256 public constant RELEASE_TIMESTAMP = 1743292800; // Fixed release timestamp for 30 March 2025

	/*
	* The constructor sets the Token for the escrow as Tratok, address: "0x35bC519E9fe5F04053079e8a0BF2a876D95D2B33".
	*
	*/
    constructor() {
        token = IERC20(0x35bC519E9fe5F04053079e8a0BF2a876D95D2B33);
    }

    /*
	* Method to create multiple escrows in one transaction.
	* This approach is used to not only save time but also significantly reduce gas costs.
	* "While testing the concept, creating 500 records in such a way saves >17,000,000 gas compared to individual escrow deposits" - Moses
	*/ 
    function deposit(address[] calldata _deliveryAddresses, uint256[] calldata _amounts) external {
        require(_deliveryAddresses.length == _amounts.length, "Arrays must be of equal length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "Amount must be greater than 0");
            totalAmount += _amounts[i];
        }

        // Ensure the total deposit has been successful
        require(token.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");

        for (uint256 i = 0; i < _deliveryAddresses.length; i++) {
            escrows[escrowCount] = Escrow({
                deliveryAddress: _deliveryAddresses[i],
                releaseTime: RELEASE_TIMESTAMP,
                amount: _amounts[i],
                released: false
            });

            escrowCount++;
        }
    }

    /*
	* Method to release all escrows at once. 
	* This approach is used as it not only is more time efficient and cost efficient but also ensures all participants are rewarded at the same time for fairness.
	* "I asked the developmer to ensure anyone could call this function once the time period elapses. I wonder if the public will be faster than us." - Mohammed
	*/
    function releaseAll() external {
        require(block.timestamp >= RELEASE_TIMESTAMP, "Tokens are still locked");

        for (uint256 i = 0; i < escrowCount; i++) {
            Escrow storage escrow = escrows[i];
            if (!escrow.released && escrow.amount > 0) {
                // Transfer the tokens
                require(token.transfer(escrow.deliveryAddress, escrow.amount), "Transfer failed");
                // Mark as released
                escrow.released = true; 
            }
        }
    }

    // Method to show the overall TRAT balance of the contract
    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Method to show escrow details for each individual escrow
    function getEscrowDetails(uint256 escrowId) external view returns (address, uint256, uint256, bool) {
        Escrow storage escrow = escrows[escrowId];
        return (escrow.deliveryAddress, escrow.releaseTime, escrow.amount, escrow.released);
    }
}
