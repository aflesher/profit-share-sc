pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    struct Owner {
        uint32 votes;
        uint32 shares;
        address owner;
    }

    struct OwnerChange {
        uint32 votes;
        uint32 shares;
        address owner;
        uint32 forCount;
        uint32 againstCount;
    }
    mapping (address => bool) ownerChangeVoted;
    OwnerChange public ownerChange;
    
    Owner public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner.owner = msg.sender;
    }


  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner.owner);
        _;
    }

}