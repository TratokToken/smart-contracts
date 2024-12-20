The following Blockchain Migration bridges are currently under developlemt

# Ethereum to BSC
This bridge uses locking and minting for migration of Tratok from the Ethereum blockchain to the BSC blockchain.

For migration from the BSC blockchain to the Ethereum blockchain it uses burning and unlocking.

The bridge is managed by a dedicated oracle maintained by Tratok.

Security is enhanced through the use of multisig wallets.

# Mechanism of Tracking Migration
**Event Monitoring:**

The oracle continuously monitors events on both blockchains. For instance, it listens for specific events emitted by smart contracts that indicate a lock or mint operation on one blockchain and a burn or unlock operation on the other.

**Cross-Chain Communication:**

When a user locks tokens on Blockchain A, the corresponding event is emitted. The oracle captures this event and can then trigger a minting operation on Blockchain B. Similarly, when tokens are burned on Blockchain B, the oracle detects this and can initiate an unlocking operation on Blockchain A.

**Data Verification:** 

The oracle ensures that the data it relays between the two blockchains is accurate and trustworthy. This is often achieved through consensus mechanisms or by using multiple data sources to confirm the validity of the events being tracked.

**State Synchronization:** 

The oracle maintains a synchronized state between the two blockchains. It keeps track of how many tokens are locked on Blockchain A and how many are minted on Blockchain B, ensuring that the total supply across both chains remains consistent and that no tokens are created or destroyed without proper authorization.

# Example Workflow
**Locking Tokens:**

A user locks 100 TRAT tokens on Blockchain A. The smart contract emits an event indicating that 100 TRAT tokens have been locked.

**Oracle Notification:** 

The oracle detects this event and verifies it.

**Minting Tokens:** 

Upon verification, the oracle sends a command to the smart contract on Blockchain B to mint 100 TRAT tokens for the user.

**Burning Tokens:** 

If the user wants to unlock their tokens, they burn 100 TRAT tokens on Blockchain B. The oracle again monitors this event.

**Unlocking Tokens:**

After confirming the burn, the oracle instructs the smart contract on Blockchain A to unlock the corresponding 100 TRAT tokens.
