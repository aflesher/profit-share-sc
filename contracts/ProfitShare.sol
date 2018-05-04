pragma solidity ^0.4.17;

import "./SafeMath.sol";
import "./SafeMath32.sol";

contract ProfitShare {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    struct Shareholder {
        uint32 votes;
        uint32 shares;
    }

    uint public outstandingVotes;
    uint public outstandingShares;

    mapping (address => Shareholder) public shareholders;
    
    constructor() public {
        
    }

    function _removeShareholder(address _shareholder) internal {
        Shareholder storage shareholder = shareholders[_shareholder];
        outstandingVotes = outstandingVotes.sub(shareholder.votes);
        outstandingShares = outstandingShares.sub(shareholder.shares);
        delete shareholders[_shareholder];
    }

    function _addShareholder(address _shareholder, uint32 _votes, uint32 _shares) internal {
        shareholders[_shareholder] = Shareholder(_votes, _shares);
        outstandingVotes = outstandingVotes.add(_votes);
        outstandingShares = outstandingShares.add(_shares);
    }

    function addShareholder(address _shareholder, uint32 _votes, uint32 _shares) external {
        _removeShareholder(_shareholder);
        _addShareholder(_shareholder, _votes, _shares);
    }
}