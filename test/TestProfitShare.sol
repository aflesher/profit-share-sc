pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ProfitShare.sol";

contract TestProfitShare {

    ProfitShare profitShare = ProfitShare(DeployedAddresses.ProfitShare());

    address address1 = 0xf4455A889fa6A6B4dd588045437c4f16cAA5445a;

    function testAddShareholder () public {
        uint expectedVotes = 10000;
        uint expectedShares = 5;
        profitShare.addShareholder(msg.sender, uint32(expectedVotes), uint32(expectedShares));
        uint32 votes;
        uint32 shares;
        (votes, shares) = profitShare.shareholders(msg.sender); 

        Assert.equal(profitShare.outstandingVotes(), expectedVotes, "Adding shareholder should update outstanding votes");
        Assert.equal(profitShare.outstandingShares(), expectedShares, "Adding shareholder should update outstanding shares");
        Assert.equal(uint(votes), expectedVotes, "Adding shareholder should update shareholder votes");
        Assert.equal(uint(shares), expectedShares, "Adding shareholder should update shareholder shares");
    }

    function testRemoveShareholder() public {
        uint startVotes = profitShare.outstandingVotes();
        uint startShares = profitShare.outstandingShares();

        profitShare.addShareholder(address1, uint32(5000), uint32(4000));
        profitShare.removeShareholder(address1);

        Assert.equal(profitShare.outstandingVotes(), startVotes, "Removing shareholder should update outstanding votes");
        Assert.equal(profitShare.outstandingShares(), startShares, "Removing shareholder should update outstanding shares");
    }

    function testUtilities() public {
        uint numerator = 11;
        uint denominator = 5;
        uint precision = 1;

        Assert.equal(profitShare.percent(numerator, denominator, precision), 22, "Division");
        Assert.equal(profitShare.percent(5, 11, 2), 45, "Division 2");
        Assert.equal((profitShare.percent(5, 11, 2) * 5000) / uint(100), 2250, "Division 3");
    }

    function testDisburse() public {
        // address(profitShare).transfer(5 wei);

        // Assert.balanceEqual(address(profitShare), 5 wei, "Balance Set");
    }
}