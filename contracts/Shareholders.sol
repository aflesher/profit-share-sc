pragma solidity ^0.4.17;

import "./SafeMath.sol";
import "./SafeMath32.sol";
import "./Ownable.sol";

contract Shareholders is Ownable {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    struct Shareholder {
        uint32 votes;
        uint32 shares;
    }
    mapping (address => Shareholder) public shareholders;
    address[] shareholderArray;

    struct ShareholderChange {
        uint32 votes;
        uint32 shares;
        address shareholder;
        uint32 forCount;
        uint32 againstCount;
    }
    mapping (address => bool) shareholderChangeVoted;
    ShareholderChange public shareholderChange;

    uint public outstandingVotes;
    uint public outstandingShares;

    constructor(address[] _shareholders, uint[] _votes, uint[] _shares) public Ownable() {
        // add inital shareholders and voters
        // use internal addshareholder
        for (uint i = 0; i < _shareholders.length; i++) {
            _addShareholder(_shareholders[i], uint32(_votes[i]), uint32(_shares[i]));
        }
    }

    modifier onlyShareholder() {
        require(shareholders[msg.sender].shares != 0);
        _;
    }

    modifier onlyVoter() {
        require(shareholders[msg.sender].votes != 0);
        _;
    }

    function _removeShareholderFromArray(address _address) internal {
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

    /**
     * @dev safe to call if shareholder doesn't exist
     */
    function _removeShareholder(address _shareholder) private {
        Shareholder storage shareholder = shareholders[_shareholder];
        outstandingVotes = outstandingVotes.sub(shareholder.votes);
        outstandingShares = outstandingShares.sub(shareholder.shares);
        delete shareholders[_shareholder];
        _removeShareholderFromArray(_shareholder);
    }

    function _addShareholder(address _shareholder, uint32 _votes, uint32 _shares) private {
        shareholders[_shareholder] = Shareholder(_votes, _shares);
        outstandingVotes = outstandingVotes.add(_votes);
        outstandingShares = outstandingShares.add(_shares);
        shareholderArray.push(_shareholder);
    }

    event ChangeShareholderProposed(address shareholder, uint32 votes, uint32 shares);
    event ChangeShareholderVoteComplete(bool passed);

    function proposeShareholderChange(address _shareholder, uint32 _votes, uint32 _shares) onlyVoter external {
        require(shareholderChange.forCount == 0 && shareholderChange.againstCount == 0);
        shareholderChange = ShareholderChange(_votes, _shares, _shareholder, 0, 0);
        voteForShareholderChange(true);
        emit ChangeShareholderProposed(_shareholder, _votes, _shares);
    }

    function voteForShareholderChange(bool _isFor) onlyVoter public {
        require(!shareholderChangeVoted[msg.sender]);
        shareholderChangeVoted[msg.sender] = true;
        if (_isFor) {
            shareholderChange.forCount = shareholderChange.forCount.add(shareholders[msg.sender].votes);
            if (shareholderChange.forCount > outstandingVotes / 2) {
                _changeShareholderVoteComplete(true);
            }
        } else {
            shareholderChange.againstCount = shareholderChange.againstCount.add(shareholders[msg.sender].votes);
            if (shareholderChange.againstCount >= outstandingVotes / 2) {
                _changeShareholderVoteComplete(false);
            }
        }
    }

    function _changeShareholderVoteComplete(bool _passed) private {
        if (_passed) {
            _removeShareholder(shareholderChange.shareholder);
            if (shareholderChange.votes > 0 || shareholderChange.shares > 0) {
                _addShareholder(shareholderChange.shareholder, shareholderChange.votes, shareholderChange.shares);
            }
        }
        // reset everything
        shareholderChange.forCount = 0;
        shareholderChange.againstCount = 0;
        for (uint i = 0; i < shareholderArray.length; i++) {
            shareholderChangeVoted[shareholderArray[i]] = false;
        }
        emit ChangeShareholderVoteComplete(_passed);
    }
}