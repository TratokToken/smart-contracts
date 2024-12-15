/**
 *Submitted for verification at Etherscan.io on 2024-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.26;

/*
This is the fourth-generation smart contract for the ERC 20 standard Tratok token.
During the development of the smart contract, active attention was paid to make the contract as simple as possible.
As the majority of functions are simple addition and subtraction of existing balances, we have been able to make the contract very lightweight.
This has the added advantage of reducing gas costs and ensuring that transaction fees remain low.
The smart contract has been made publically available, keeping with the team's philosophy of transparency.
This is an update on the third generation smart contract which can be found at 0xe225aca29524bb65fd82c79a9602f3b4f9c6fe3f.
The contract has been updated to in response to adhering to best practices, increasing security and paying attention to community wishes.

@version "1.3"
@developer "Tratok Team"
@date "8 August 2024"
@thoughts "As always we will evolve at the forefront and strive to serve the interests of our users"
*/

/*
 * Use of the SafeMath Library prevents malicious input. For security consideration, the
 * smart contract makes use of .add() and .sub() rather than += and -=
 */


library SafeMath {
    // Ensures that b is less than or equal to a to handle negatives.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    // Ensures that the sum of two values does not overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
}


abstract contract ERC20 {
    //the total supply of tokens

    //@return Returns the total amount of Tratok tokens in existence. The amount remains capped at the pre-created 100 Billion.  
    function totalSupply() public view virtual returns (uint256);

    /* 
      @param account The address of the wallet which needs to be queried for the amount of Tratok held. 
      @return Returns the balance of Tratok tokens for the relevant address.
      */
    function balanceOf(address account) public view virtual returns (uint256);

    /* 
       The transfer function which takes the address of the recipient and the amount of Tratok needed to be sent and complete the transfer
       @param recepient The address of the recipient (usually a "service provider") who will receive the Tratok.
       @param amount The amount of Tratok that needs to be transferred.
       @return Returns a boolean value to verify the transaction has succeeded or failed.
      */
    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    /*
       This function will, conditional of being approved by the holder, send a determined amount of tokens to a specified address
       @param sender The address of the Tratok sender.
       @param recepient The address of the Tratok recipient.
       @param amount The volume (amount of Tratok which will be sent).
       @return Returns a boolean value to verify the transaction has succeeded or failed.
      */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

    /*
      This function approves the transaction and costs
      @param spender The address of the account which is able to transfer the tokens
      @param amount The amount of wei to be approved for transfer
      @return Whether the approval was successful or not
     */
    function approve(address spender, uint256 amount) external virtual returns (bool);

    /*
    This function determines how many Tratok remain and how many can be spent.
     @param owner The address of the account owning the Tratok tokens
     @param spender The address of the account which is authorized to spend the Tratok tokens
     @return Amount of Tratok tokens which remain available and therefore, which can be spent
    */
    function allowance(address owner, address spender) public view virtual returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

/*
 *This is a basic contract held by one owner and prevents function execution if attempts to run are made by anyone other than the owner of the contract
 */

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract StandardToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    uint256 public _totalSupply;

    function transfer(address _to, uint256 _value) override external returns (bool success) {
        require(_value > 0, "Transfer value must be greater than 0");
        require(_balances[msg.sender] >= _value, "Insufficient balance");

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override external returns (bool success) {
        require(_value > 0, "Transfer value must be greater than 0");
        require(_balances[_from] >= _value, "Insufficient balance");
        require(_allowed[_from][msg.sender] >= _value, "Allowance exceeded");

        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value) override external returns (bool success) {
        require(_value == 0 || _allowed[msg.sender][_spender] == 0, "Reset allowance to zero before changing it");
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowed[_owner][_spender];
    }

     function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
}

contract Tratok is StandardToken {
    string public name = "Tratok";
    string public symbol = "TRAT";
    uint8 public decimals = 5;
    
    event Initialized(uint256 totalSupply, address owner);

    constructor() {
        _totalSupply = 100000000000*10**decimals; // 10^5 to represent 5 decimals
        _balances[msg.sender] = _totalSupply;
        emit Initialized(_totalSupply, msg.sender);
    }
	
    fallback() external payable {
    revert("Your request does not match any function signature.");
	}
    
	receive() external payable {
        revert("Direct payments are not accepted.");
    }
}