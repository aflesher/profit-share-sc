pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ProfitShare.sol";

contract TestProfitShare {
    function testAddShareholder () public {
        ProfitShare profitShare = ProfitShare(DeployedAddresses.ProfitShare());

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
}