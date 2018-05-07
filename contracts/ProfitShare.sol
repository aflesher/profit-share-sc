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
    uint public companyShares = 1000;
    uint public lastPayout;
    uint public minPayoutBalance = 500 wei;
    uint public payoutCooldown = 23 hours + 30 minutes;
    address escrowManager;

    mapping (address => Shareholder) public shareholders;
    address[] shareholderArray;
    
    constructor() public payable {
        escrowManager = msg.sender;
    }

    modifier onlyShareholder() {
        require(shareholders[msg.sender].shares != 0 || msg.sender == escrowManager);
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
            address owner = shareholderArray[i];
            Shareholder storage shareholder = shareholders[owner];
            uint share = (percent(shareholder.shares, outstandingShares, 4) * balance) / 10000;
            owner.transfer(share);
        }

    }
}