var ProfitShare = artifacts.require("ProfitShare");

contract('ProfitShare', function (accounts) {
  it ("should have a blance of zero", function () {
    return ProfitShare.deployed().then(function (instance) {
      return web3.eth.getBalance(ProfitShare.address);
    }).then(function (balance) {
      assert.equal(balance.valueOf(), 0, "Empty to start");
    })
  });

  it("should receive tokens", function() {
    var sendAmount = 5000;

    return ProfitShare.deployed().then(function(instance) {
      return web3.eth.sendTransaction({from: accounts[0], to: ProfitShare.address, value: sendAmount});
    }).then(function () {
      return web3.eth.getBalance(ProfitShare.address);
    }).then((balance) => {
      assert.equal(balance.valueOf(), sendAmount, "Received balance");
    });
  });

  it("should add shareholders", () => {
    var expectedVotes = 10000;
    var expectedShares = 5;
    var shareholder = accounts[1];
    var ps;

    return ProfitShare.deployed().then(function(instance) {
      ps = instance;
      return ps.addShareholder.call(shareholder, expectedVotes, expectedShares);
    }).then(function() {
      return ps.outstandingVotes.call();
    }).then(function(votes) {
      console.log(votes.toNumber());
      assert.equal(votes.toNumber(), expectedVotes, "Votes");
    });
  })
});