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
    uint public lastPayout;
    uint public minPayoutBalance = 500 wei;
    uint public payoutCooldown = 23 hours + 30 minutes;

    mapping (address => Shareholder) public shareholders;
    address[] shareholderArray;

    address public escrowManager;
    uint public escrowShares;

    uint votesForNewEscrowShares;
    uint votesAgainstNewEscrowShares;
    uint proposedEscrowShares;
    mapping(address => bool) votersForNewEscrowShares;

    
    constructor() public payable {
        escrowManager = msg.sender;
    }

    modifier onlyShareholder() {
        require(shareholders[msg.sender].shares != 0 || msg.sender == escrowManager);
        _;
    }

    modifier onlyVoter() {
        require(shareholders[msg.sender].votes != 0);
        _;
    }

    function _removeOwner(address _address) internal {
        if (shareholderArray.length == 0) {
            return;
        }
        bool found = false;
        for (uint i = 0; i < shareholderArray.length; i++) {
            if (found) {
                shareholderArray[i - 1] = shareholderArray[i];
            }

            if (!found) {
                found = shareholderArray[i] == _address;
            }
        }

        if (found) {
            shareholderArray.length--;
        }
    }

    function percent(uint numerator, uint denominator, uint precision) public pure returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function _removeShareholder(address _shareholder) internal {
        Shareholder storage shareholder = shareholders[_shareholder];
        outstandingVotes = outstandingVotes.sub(shareholder.votes);
        outstandingShares = outstandingShares.sub(shareholder.shares);
        delete shareholders[_shareholder];
        _removeOwner(_shareholder);
    }

    function _addShareholder(address _shareholder, uint32 _votes, uint32 _shares) internal {
        shareholders[_shareholder] = Shareholder(_votes, _shares);
        outstandingVotes = outstandingVotes.add(_votes);
        outstandingShares = outstandingShares.add(_shares);
        shareholderArray.push(_shareholder);
    }

    function addShareholder(address _shareholder, uint32 _votes, uint32 _shares) external {
        _removeShareholder(_shareholder);
        _addShareholder(_shareholder, _votes, _shares);
    }

    function removeShareholder(address _shareholder) external {
        _removeShareholder(_shareholder);
    }

    // `fallback` function called when eth is sent to Payable contract
    function () public payable {
    }

    function disburse() onlyShareholder external {
        require((now > lastPayout + payoutCooldown) && (address(this).balance > minPayoutBalance));
        lastPayout = now;
        uint balance = address(this).balance;
        for (uint i = 0; i < shareholderArray.length; i++) {
            address shareholder = shareholderArray[i];
            uint share = (percent(shareholders[shareholder].shares, outstandingShares, 4) * balance) / 10000;
            shareholder.transfer(share);
        }

    }

    event ChangeEscrowVoteComplete();
    event ChangeEscrowVotesProposed(uint shares);

    function changeEscrowShares(uint _shares) external {
        require(proposedEscrowShares == 0);
        proposedEscrowShares = _shares;
        emit ChangeEscrowVotesProposed(proposedEscrowShares);
    }

    function voteForChangeEscrowShares(bool _isFor) onlyVoter  external {
        require(!votersForNewEscrowShares[msg.sender]);
        votersForNewEscrowShares[msg.sender] = true;
        if (_isFor) {
            votesForNewEscrowShares = votesForNewEscrowShares.add(shareholders[msg.sender].votes);
            if (votesForNewEscrowShares > outstandingVotes / 2) {
                emit ChangeEscrowVoteComplete();
            }
        } else {
            votesAgainstNewEscrowShares = votesAgainstNewEscrowShares.add(shareholders[msg.sender].votes);
            if (votesAgainstNewEscrowShares >= outstandingVotes / 2) {
                emit ChangeEscrowVoteComplete();
            }
        }
    }

    function _cleanupEscrowShareVote() private {
        proposedEscrowShares = 0;
        votesForNewEscrowShares = 0;
        votesAgainstNewEscrowShares = 0;
        for (uint i = 0; i < shareholderArray.length; i++) {
            delete votersForNewEscrowShares[shareholderArray[i]];
        }
    }

    // only owner
    function completeVoteForChangeEscrowShares() external {
        require((votesForNewEscrowShares > outstandingVotes / 2) || (votesAgainstNewEscrowShares >= outstandingVotes / 2));
        if (votesForNewEscrowShares > votesAgainstNewEscrowShares) {
            escrowShares = proposedEscrowShares;
        }
    }
}