/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

contract MultiSigWallet is ReentrancyGuard {
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owners can call this function");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(ownerCount > 0 && _required > 0 && _required <= ownerCount, "Invalid requirement");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) validRequirement(_owners.length, _required) {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner(_owners[i]) && _owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }
        required = _required;
    }

    function isOwner(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address destination, uint256 value, bytes memory data) public onlyOwner returns (uint256) {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    function confirmTransaction(uint256 transactionId) public onlyOwner {
        require(transactions[transactionId].destination != address(0), "Transaction does not exist");
        require(!confirmations[transactionId][msg.sender], "Transaction already confirmed by this owner");

        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);

        executeTransaction(transactionId);
    }

    function addTransaction(address destination, uint256 value, bytes memory data) internal returns (uint256) {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }

    // Use nonReentrant to prevent reentrancy attacks
    function executeTransaction(uint256 transactionId) public nonReentrant {
        require(!transactions[transactionId].executed, "Transaction already executed");
        Transaction storage t = transactions[transactionId];

        if (isConfirmed(transactionId)) {
            t.executed = true;
            (bool success, ) = t.destination.call{value: t.value}(t.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
            }
        }
    }

    // Improved isConfirmed to ensure correct counting of confirmations
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
                if (count >= required) {
                    return true;
                }
            }
        }
        return false;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function encodeCall(address contractAddress, bytes4 functionSignature, bytes memory params) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(functionSignature, params);
    }

    function mintTokens(address to, uint256 amount) public onlyOwner {
        bytes memory data = encodeCall(address(this), bytes4(keccak256("mint(address,uint256)")), abi.encode(to, amount));
        submitTransaction(address(this), 0, data);
    }

    function unlockTokens(address bridge, address user, uint256 amount) public onlyOwner {
        bytes memory data = encodeCall(bridge, bytes4(keccak256("unlockTokens(address,uint256)")), abi.encode(user, amount));
        submitTransaction(bridge, 0, data);
    }

    // Owner Management Functions

    /**
     * @dev Adds a new owner to the wallet.
     * @param owner Address of the new owner.
     */
    function addOwner(address owner) public onlyOwner {
        require(!isOwner(owner), "Owner already exists");
        require(owner != address(0), "Invalid owner address");
        require(owners.length + 1 > required, "Cannot add owner if it would make the requirement invalid");

        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /**
     * @dev Removes an owner from the wallet.
     * @param owner Address of the owner to remove.
     */
    function removeOwner(address owner) public onlyOwner {
        require(isOwner(owner), "Not an owner");
        require(owners.length - 1 >= required, "Cannot remove owner if it would make the requirement invalid");

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                emit OwnerRemoval(owner);
                return;
            }
        }
        revert("Owner not found");
    }

    /**
     * @dev Changes the number of required confirmations.
     * @param _required New number of confirmations required.
     */
    function changeRequirement(uint256 _required) public onlyOwner {
        require(_required > 0 && _required <= owners.length, "Invalid requirement");
        required = _required;
        emit RequirementChange(_required);
    }
}