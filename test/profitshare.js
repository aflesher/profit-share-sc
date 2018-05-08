var ProfitShare = artifacts.require("ProfitShare"),
  _ = require('lodash');

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

function didComplete(aPromise) {
  return new Promise((resolve) => {
    aPromise().then(() => {
      resolve(true);
    }).catch(() => {
      resolve(false);
    });
  });
}

contract('ProfitShare', async (accounts) => {
  var owner = accounts[0],
    a1 = {a: accounts[1], v: 500, s:1000},
    a2 = {a: accounts[2], v: 1500, s:2000},
    a3 = {a: accounts[3], v: 700, s:500},
    a4 = {a: accounts[4], v: 4000, s:5000},
    a5 = {a: accounts[5], v: 4000, s:5000},
    ps;
  
  beforeEach('deploy new contract', async () => {
    ps = await ProfitShare.new([a1.a, a2.a, a3.a], [a1.v, a2.v, a3.v], [a1.s, a2.s, a3.s]);
  });

  it ('should have shareholders', async () => {
    let s1 = await ps.shareholders.call(a1.a);
    assert.equal(s1[0].toNumber(), a1.v, 'a1 votes');
    assert.equal(s1[1].toNumber(), a1.s, 'a1 shares');

    let totalShares = await ps.outstandingShares.call();
    assert.equal(totalShares.toNumber(), a1.s + a2.s + a3.s, 'outstanding shares');

    let totalVotes = await ps.outstandingVotes.call();
    assert.equal(totalVotes.toNumber(), a1.v + a2.v + a3.v, 'outstanding votes');
  });

  it ("should have a blance of zero", async () => {
    let balance = await web3.eth.getBalance(ps.address);
    assert.equal(balance.valueOf(), 0, "Empty to start");
  });

  it("should receive tokens", async () => {
    let sendAmount = 5000;
    await web3.eth.sendTransaction({from: owner, to: ps.address, value: sendAmount});
    let balance = await web3.eth.getBalance(ps.address);
    assert.equal(balance.valueOf(), sendAmount, "Received balance");
  });

  it('should allow for shareholder votes', async() => {
    let resp = await ps.proposeShareholderChange(a4.a, a4.v, a4.s, {from: a1.a});
    assert.notEqual(_.findIndex(resp.logs, {event: 'ChangeShareholderProposed'}), -1, "proposal change fired");

    let resp2 = await ps.voteForShareholderChange(true, {from: a3.a});
    assert.equal(_.findIndex(resp2.logs, {event: 'ChangeShareholderVoteComplete'}), -1, "vote not over");

    let resp3 = await ps.voteForShareholderChange(true, {from: a2.a});
    assert.notEqual(_.findIndex(resp3.logs, {event: 'ChangeShareholderVoteComplete'}), -1, "vote over");

    let s4 = await ps.shareholders.call(a4.a);
    assert.equal(s4[0].toNumber(), a4.v, 'a4 votes');
    assert.equal(s4[1].toNumber(), a4.s, 'a4 shares');

    let resp4 = await ps.proposeShareholderChange(a5.a, a5.v, a5.s, {from: a2.a});
    assert.notEqual(_.findIndex(resp4.logs, {event: 'ChangeShareholderProposed'}), -1, "a new proposal can be created");
  });

  it('should disburse funds', async () => {
    let sendAmount = 5000;
    let totalShares = a1.s + a2.s + a3.s;
    await web3.eth.sendTransaction({from: owner, to: ps.address, value: sendAmount});
    let balance = await web3.eth.getBalance(ps.address);
    assert.equal(balance.toNumber(), sendAmount, "new balance");

    let a1balance = await web3.eth.getBalance(a1.a); 
    let a2balance = await web3.eth.getBalance(a2.a);

    let a1expected = add(Math.floor((a1.s / totalShares) * sendAmount) + "", a1balance.valueOf());
    let a2expected = add(Math.floor((a2.s / totalShares) * sendAmount) + "", a2balance.valueOf());
    await ps.disburse({from: a3.a});

    let a1newBalance = await web3.eth.getBalance(a1.a); 
    assert.equal(a1newBalance.valueOf(), a1expected, 'account 1 got expected funds');
    let a2newBalance = await web3.eth.getBalance(a2.a); 
    assert.equal(a2newBalance.valueOf(), a2expected, 'account 2 got expected funds');
    // don't check a3, the balance will be off because they have to pay the gas for the disburse
  });
});