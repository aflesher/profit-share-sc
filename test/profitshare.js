var ProfitShare = artifacts.require("ProfitShare");

function add (a, b) {
  let res = '', c = 0
  a = a.split('')
  b = b.split('')
  while (a.length || b.length || c) {
    c += ~~a.pop() + ~~b.pop()
    res = c % 10 + res
    c = c > 9
  }
  return res
}

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

  it("should add a shareholder", () => {
    var expectedVotes = 10000;
    var expectedShares = 5;
    var shareholder = accounts[1];
    var ps;

    return ProfitShare.deployed().then(function(instance) {
      ps = instance;
      return ps.addShareholder(shareholder, expectedVotes, expectedShares);
    }).then(function() {
      return Promise.all([ps.outstandingVotes.call(), ps.outstandingShares.call(), ps.shareholders.call(shareholder)]);
    }).then(function(resp) {
      assert.equal(resp[0].toNumber(), expectedVotes, "Votes");
      assert.equal(resp[1].toNumber(), expectedShares, "Shares");
      assert.equal(resp[2][0].toNumber(), expectedVotes, "Votes");
      assert.equal(resp[2][1].toNumber(), expectedShares, "Shares");
    });
  });

  it("should remove a shareholder", () => {
    var shareholder = accounts[2],
      currentVotes,
      currentShares,
      ps;

    return ProfitShare.deployed().then((instance) => {
      ps = instance;
      return Promise.all([ps.outstandingVotes.call(), ps.outstandingShares.call()]);
    }).then((resp) => {
      currentVotes = resp[0];
      currentShares = resp[1];
      return ps.addShareholder(shareholder, 800, 50000);
    }).then(() => {
      return ps.removeShareholder(shareholder);
    }).then(() => {
      return Promise.all([ps.outstandingVotes.call(), ps.outstandingShares.call(), ps.shareholders.call(shareholder), ps.arraySize.call()]);
    }).then((resp) => {
      assert.equal(resp[0].toNumber(), currentVotes, "Votes");
      assert.equal(resp[1].toNumber(), currentShares, "Shares");
      assert.equal(resp[2][0].toNumber(), 0, "Votes");
      assert.equal(resp[2][1].toNumber(), 0, "Shares");
    });
  });

  it ("should send funds", () => {
    var ps,
      funds;

    return ProfitShare.deployed().then((instance) => {
      ps = instance;
      return web3.eth.getBalance(accounts[6]);
    }).then((resp) => {
      funds = resp.toNumber();
      return ps.sendTest(accounts[6]);
    }).then(() => {
      return web3.eth.getBalance(accounts[6]);
    }).then((balance) => {
      assert.equal(balance.toNumber(), 100 + funds, "Received balance");
    });
  });

  it("should disburse funds", () => {
    var shareholder1 = { a: accounts[2], v: 0, s: 300 },
      shareholder2 = { a: accounts[3], v: 0, s: 600 },
      shareholder3 = { a: accounts[4], v:0, s: 2000 },
      ps;

    return ProfitShare.deployed().then((instance) => {
      ps = instance;
      return Promise.all([
        web3.eth.getBalance(ProfitShare.address),
        web3.eth.getBalance(shareholder1.a), 
        web3.eth.getBalance(shareholder2.a),
        web3.eth.getBalance(shareholder3.a)
      ]);
    }).then((resp) => {
      var total = shareholder1.s + shareholder2.s + shareholder3.s;
      shareholder1.e = add(Math.floor((shareholder1.s / total) * resp[0].toNumber()) + "", resp[1].valueOf());
      shareholder2.e = add(Math.floor((shareholder2.s / total) * resp[0].toNumber()) + "", resp[2].valueOf());
      shareholder3.e = add(Math.floor((shareholder3.s / total) * resp[0].toNumber()) + "", resp[3].valueOf());
      return Promise.all([
        ps.addShareholder(shareholder1.a, shareholder1.v, shareholder1.s),
        ps.addShareholder(shareholder2.a, shareholder2.v, shareholder2.s),
        ps.addShareholder(shareholder3.a, shareholder3.v, shareholder3.s),
        ps.removeShareholder(accounts[1])
      ]);
    }).then(() => {
      return ps.disburse();
    }).then(() => {
      return Promise.all([
        web3.eth.getBalance(shareholder1.a),
        web3.eth.getBalance(shareholder2.a),
        web3.eth.getBalance(shareholder3.a)
      ]);
    }).then((resp) => {
      assert.equal(resp[0].valueOf(), shareholder1.e, "Shareholder 1 value");
      assert.equal(resp[1].valueOf(), shareholder2.e, "Shareholder 2 value");
      assert.equal(resp[2].valueOf(), shareholder3.e, "Shareholder 3 value");
    });
  });
});