pragma solidity ^0.4.17;

import "./SafeMath.sol";
import "./SafeMath8.sol";

contract ProfitShare {
    
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    struct Shareholder {
        uint8 votes;
        uint8 shares;
    }

    uint public outstandingVotes;
    uint public outstandingShares;

    mapping (address => Shareholder) shareholders;
    
    constructor() public {
        
    }

    function removeShareholder(address _shareholder) public {
        Shareholder storage shareholder = shareholders[_shareholder];
        outstandingVotes = outstandingVotes.sub(shareholder.votes);
        outstandingShares = outstandingShares.sub(shareholder.shares);
        delete shareholders[_shareholder];
    }

    // _transfersend ether to member
    function addShareholder(address _shareholder, uint8 _votes, uint8 _shares) external {
        removeShareholder(_shareholder);
        shareholders[_shareholder] = Shareholder(_votes, _shares);
        outstandingVotes = outstandingVotes.add(_votes);
        outstandingShares = outstandingShares.add(_shares);
    }
}