// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredSignatures;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) isConfirmed;
    }

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length > 0, "Owners required");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid number of required signatures");

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        requiredSignatures = _requiredSignatures;
    }

    function submitTransaction(address to, uint256 value) public onlyOwner {
        transactions.push(Transaction({
            to: to,
            value: value,
            executed: false,
            confirmations: 0
        }));
    }

    function confirmTransaction(uint256 txIndex) public onlyOwner {
        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isConfirmed[msg.sender], "Transaction already confirmed");
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;

        if (transaction.confirmations >= requiredSignatures) {
            executeTransaction(txIndex);
        }
    }

    function executeTransaction(uint256 txIndex) internal {
        Transaction storage transaction = transactions[txIndex];
        require(transaction.confirmations >= requiredSignatures, "Not enough confirmations");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction failed");
    }

    // Function to withdraw ETH from the wallet
    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Fallback function to receive ETH
    receive() external payable {}
}