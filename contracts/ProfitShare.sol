pragma solidity ^0.4.17;

import "./SafeMath.sol";
import "./SafeMath32.sol";
import "./Shareholders.sol";

contract ProfitShare is Shareholders {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    uint public lastPayout;
    uint public minPayoutBalance = 500 wei;
    uint public payoutCooldown = 23 hours + 30 minutes;

    
    constructor(address[] _shareholders, uint[] _votes, uint[] _shares) public
        Shareholders(_shareholders, _votes, _shares) payable {
    }

    function percent(uint numerator, uint denominator, uint precision) public pure returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
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

    // `fallback` function called when eth is sent to Payable contract
    function () public payable {
    }
}