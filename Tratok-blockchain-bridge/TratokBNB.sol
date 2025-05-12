// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
* Explanation:
*
* This is the smart contract used as a bridge for migrating Tratok (TRAT) from the BNB
* blockchain to the Ethereum blockchain and vice versa.
* 
* Methodology:
*
* The contract features a minting functionality to mint TRAT for a user on the BNB whenever they
* migrate Tratok (TRAT) tokens from the Ethereum blockchain. The contract also features a 
* burn function for when users wish to migrate their tokens from the BNB blockchain to the Ethereum 
* blockchain. All events are monitored by Tratok's off-chain oracle to ensure circulations supply
* remains unchanged.
*
*
* Risks: 
* 
* Users may fall victim to phishing attacks where malicious actors create fake interfaces or contracts
* that mimic the legitimate locking contract. This can lead to users inadvertently sending funds to the
* wrong address or interacting with a fraudulent contract. This can be mitigated by using the official
* bridge portal. https://bridge.tratok.com
* 
* The contract grants significant powers to the admin, including the ability to mint new tokens and withdraw
* BNB fees. If the admin's private key is compromised, an attacker could gain control over the contract, 
* potentially draining funds or manipulating token unlocks. This is mitigated through best security
* practices including making the admin wallet a Multi-Signature Wallet which requires multiple private 
* keys to authorize critical actions, such as unlocking tokens or withdrawing BNB fees. By distributing 
* control among several trusted parties, the risk of a single compromised key leading to fund loss is 
* significantly reduced. In the unlikely event that a key is compromised, its permissions may be revoked by the other
* owners.
*
* Sustainability:
* 
* To ensure sustainability of the bridge and prevent abuse, the contract collects a fee every time a migration from
* the BSC blockchain to Ethereum blockchain is performed. This fee can be changed to reflect network
* congestion via the setBNBFee method.
* 
* @version "1.2"
* @developer "Tratok Team"
* @date "12 May 2025"
* @thoughts "The Worlds Travel Token Needs To Be On Every Global Blockchain!" 
*/


import "./MultiSigWallet.sol";

contract TratokBNB {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    // Multi-signature wallet is used to enhance security
    MultiSigWallet public multiSigWallet;

    // Maximum supply (in wei) set at 100,000,000,000 with 5 decimals
    uint256 public constant MAX_SUPPLY = 100_000_000_000 * 10**5;

    // 5 decimal places set to be consistent
    uint8 public constant DECIMALS = 5;

    // Event declaration for burning tokens
    event TokensBurned(address indexed user, uint256 amount);

    // Fee for burning tokens in BNB
    uint256 public burnFee;

    // Total collected fees in BNB
    uint256 public totalFeesCollected;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event BurnFeeUpdated(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address[] memory owners, uint256 requiredSignatures) {
        name = "Tratok";
        symbol = "TRAT";
        decimals = DECIMALS;
        totalSupply = 0; // Initialize total supply to zero
        owner = msg.sender; // Set the contract deployer as the owner

        // Initialize the multi-signature wallet
        multiSigWallet = new MultiSigWallet(owners, requiredSignatures);
        burnFee = 0; // Initialize burn fee to zero
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Mints new tokens to the specified address.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        require(msg.sender == address(multiSigWallet), "Only multi-signature wallet can mint tokens");
        require(totalSupply + amount <= MAX_SUPPLY, "Minting exceeds max supply");

        // Update the balance and total supply
        balanceOf[to] += amount;
        totalSupply += amount;

        // Emit Transfer event for minting
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }

    /**
     * @dev Allows users to burn their own tokens so they can be migrated to Ethereum blockchain.
     * @param amount The amount of tokens to burn (in wei).
     */
    function burn(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= burnFee, "Insufficient BNB sent for burn fee");
        require(amount <= balanceOf[msg.sender], "Insufficient TRAT balance to burn");

        // Update the balance and total supply
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        // Emit Transfer event for burning
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);

        // Collect the burn fee
        totalFeesCollected += msg.value;

        // Emit event on burn
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Set the burn fee in BNB.
     * @param newFee The new burn fee (in wei).
     */
    function setBurnFee(uint256 newFee) public {
        require(msg.sender == address(multiSigWallet), "Only multi-signature wallet can set burn fee");
        burnFee = newFee;
        emit BurnFeeUpdated(newFee); // Added event for updating burn fee
    }

    /**
     * @dev Withdraw collected fees to the multi-signature wallet.
     */
    function withdrawFees() public {
        require(msg.sender == address(multiSigWallet), "Only multi-signature wallet can withdraw fees");
        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0; // Reset the fee counter after transfer
        (bool success, ) = address(multiSigWallet).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Check the total fees collected in BNB.
     * @return The total fees collected in BNB.
     */
    function checkTotalFeesCollected() public view returns (uint256) {
        return totalFeesCollected;
    }

    // Fallback function to receive BNB
    receive() external payable {}
}
