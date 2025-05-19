// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
* Explanation:
*
* This is the smart contract used as a bridge for migrating Tratok (TRAT) from the Ethereum
* blockchain to the BNB blockchain and vice versa.
* 
* Methodology:
*
* The contract is initialized with the address of the Tratok token (TRAT), allowing it to interact
* with the existing token.
* It features a locking functionality so users can lock their TRAT tokens by calling the lockTokens
* function, which transfers the specified amount of tokens from the user's address to the contract.
* The contract then emits a TokensLocked event whenever tokens are locked, which is monitored by
* Tratok's off-chain oracle to trigger the minting of BEP20 tokens on BNB at the desired address of
* of the user.
*
* Fail safe:
*
* The admin (the address that deployed the contract) can withdraw any locked tokens if necessary.
* In case of a malfunction or unexpected issue with the contract, the admin can withdraw tokens to 
* prevent loss or misuse. This feature acts as a safety net, allowing the admin to respond quickly to
* emergencies.
*
* Risks: 
* 
* Users may fall victim to phishing attacks where malicious actors create fake interfaces or contracts
* that mimic the legitimate locking contract. This can lead to users inadvertently sending funds to the
* wrong address or interacting with a fraudulent contract. This can be mitigated by using the official
* bridge portal. https://bridge.tratok.com
* 
* The contract grants significant powers to the admin, including the ability to unlock tokens and withdraw
* ETH fees. If the admin's private key is compromised, an attacker could gain control over the contract, 
* potentially draining funds or manipulating token unlocks. This is mitigated through best security
* practices including making the admin wallet a Multi-Signature Wallet which requires multiple private 
* keys to authorize critical actions, such as unlocking tokens or withdrawing ETH fees. By distributing 
* control among several trusted parties, the risk of a single compromised key leading to fund loss is 
* significantly reduced. In addition in case of a key being compromised, it permisions can be revoked mitigating any damage.
*
* Sustainability:
* 
* To ensure sustainability of the bridge and prevent abuse the contract collects a fee every time a migration from
* the Ethereum blockchain to BNB blockchain is performed. This fee can be changed to reflect network
* congestion via the setEthFee method.
* 
* @version "1.2"
* @developer "Tratok Team"
* @date "12 May 2025"
* @thoughts "The Worlds Travel Token Needs To Be On Every Global Blockchain!" 
*/

import "./IERC20.sol";
import "./MultiSigWallet.sol";

contract TratokBNBBridge {
    IERC20 public token;
    MultiSigWallet public multiSigWallet;
    uint256 public ethFee;
	uint256 public tokensLocked;

    event TokensLocked(address indexed user, uint256 amount);
    event TokensUnlocked(address indexed user, uint256 amount);
    event FeeUpdated(uint256 newFee);
    event AdminWithdrawn(uint256 amount);
    event ETHWithdrawn(address indexed recipient, uint256 amount);

    constructor(address[] memory owners, uint256 requiredSignatures) {
        // Set the address as the Tratok Token: "0x35bC519E9fe5F04053079e8a0BF2a876D95D2B33"
        token = IERC20(0x35bC519E9fe5F04053079e8a0BF2a876D95D2B33);
        
        // Create a new MultiSigWallet within the constructor
        multiSigWallet = new MultiSigWallet(owners, requiredSignatures);
    }

    /*
    * Function to lock TRAT tokens in the contract.  This method is called when someone wishes to migrate Tratok (TRAT) 
    * from the Ethereum blockchain to the BNB blockchain. Locking the tokens and removing them from supply before minting
    * an equal amount of tokens on the BNB blockchain ensures the circulating supply remains unchanged.
    */
    
    function lockTokens(uint256 amount) external payable {
        // Ensure the amount is positive
        require(amount > 0, "TRAT amount must be greater than zero");

        // Check if the user has sent enough ETH to cover the fee
        require(msg.value >= ethFee, "Insufficient ETH sent to cover the migration fee");

        // Transfer TRAT tokens from the user to the contract
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer TRAT from user to contract");
        tokensLocked += amount;

        // Emit an event indicating tokens have been locked 
        emit TokensLocked(msg.sender, amount); 

        // If the user sent more than the fee, refund the excess
        if (msg.value > ethFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - ethFee}("");
            require(success, "Failed to refund excess ETH to user");
        }
    }

    /*
    * Function to unlock TRAT tokens and release them from the contract. This method is called when
    * someone wishes to migrate Tratok (TRAT) from the BNB blockchain to the Ethereum blockchain. 
    * The TRAT on BNB is burned beforehand in order to ensure that the circulating supply remains
    * the same.
    */
    function unlockTokens(address user, uint256 amount) external {
        require(msg.sender == address(multiSigWallet), "Only the admin (MultiSigWallet) can unlock tokens");
        require(tokensLocked >= amount, "Not enough locked tokens in contract to unlock");
        
        // Transfer tokens to the user
        require(token.transfer(user, amount), "Failed to transfer unlocked TRAT to user");
        tokensLocked -= amount;
        
        emit TokensUnlocked(user, amount);
    }

    /*
    * This function allows the admin to withdraw any locked TRAT tokens from the contract.
    * It checks that the caller is the admin and transfers the specified amount of tokens 
    * to the admin's address. This is an important function to ensure tokens are not lost from circulation
    * in the event of bridge failure or accidental calling of lockTokens function by the public.
    */
    function withdrawTokens(uint256 amount) external {
        // Ensure only admin can withdraw locked tokens
        require(msg.sender == address(multiSigWallet), "Only the admin (MultiSigWallet) can withdraw tokens");
        
        // Transfer tokens to admin
        require(token.transfer(address(multiSigWallet), amount), "Failed to transfer tokens to admin");
        emit AdminWithdrawn(amount);
    }

    // Function for the admin to withdraw any ETH collected as fees
    function withdrawETH(address payable recipient) external {
    	require(msg.sender == address(multiSigWallet), "Only the admin (MultiSigWallet) can withdraw ETH");
    	require(recipient != address(0), "Invalid recipient address");
    	uint256 balance = address(this).balance;
    	require(balance > 0, "No ETH available to withdraw");
    	(bool success, ) = recipient.call{value: balance}("");
    	require(success, "Failed to send ETH to recipient");
    	emit ETHWithdrawn(recipient, balance);
    }

    // Function to set a new ETH fee (only callable by admin)
    function setEthFee(uint256 newFee) external {
        require(msg.sender == address(multiSigWallet), "Only admin can set fee");
        ethFee = newFee; 
        emit FeeUpdated(newFee);
    }

    // Function to get the current ETH fee
    function getEthFee() external view returns (uint256) {
        return ethFee;
    }

    // Function to check the contract's ETH balance
    function checkETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Allow contract to receive ETH
    receive() external payable {}
}
