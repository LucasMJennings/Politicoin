// const assert = require("assert");
// const ganache = require("ganache-cli");
// const options = { gasLimit: 1000000000000000000000000000000 };
// const Web3 = require("web3");
// const web3 = new Web3(ganache.provider(options));
// const json = require("./../build/contracts/AdCoin.json");

const AdCoin = artifacts.require('AdCoin');

// contract('AdCoin Test 1'), async (accounts) => {
//
//   it('should deploy', async () => {
//     let instance = await AdCoin.new();
//     assert.ok(AdCoin.options.address);
//   });
// }

// let accounts;
// let AdCoin;
// let manager;
// const interface = json["abi"];
// const bytecode = json["bytecode"];
//
// beforeEach(async () => {
//   accounts = await web3.eth.getAccounts();
//   manager = accounts[0];
//   user1 = accounts[1];
//   user2 = accounts[2];
//   AdCoin = await new web3.eth.Contract(interface)
//       .deploy({ data: bytecode })
//       .send({ from: manager, gas: "100000000" });
// });

contract('AdCoin', async (accounts) => {
  const manager = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];
  it("deploys a contract", () => {
    assert.ok(AdCoin.new());
  });
  it("distributes tokens", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000" });
    const user1bal = await politicoin.balanceOf.call(user1);
    const user2bal = await politicoin.balanceOf.call(user2);
    assert.equal(user1bal, 500);
    assert.equal(user2bal, 1000);
  });
  it("only a manager can distribute", async () => {
    const politicoin = await AdCoin.new();
      try {
        await politicoin.distribute([user2], [500], { from: user1, gas: "100000000" });
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("whitelists Addresses", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.whiteListAddresses([user1, user2], { from: manager, gas: "100000000"});
    const whitelist1 = await politicoin.isWhiteListed.call(user1);
    const whitelist2 = await politicoin.isWhiteListed.call(user2);
    assert.equal(whitelist1, true);
    assert.equal(whitelist2, true);
  });
  it("only a manager can whitelist", async () => {
    const politicoin = await AdCoin.new();
      try {
        await politicoin.whiteListAddresses([user2], [500], { from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("creates a ballot", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
    const ballot = await politicoin.showBallot.call(0);
    assert.equal(ballot[0], "George Washington");
    await politicoin.createBallot("Thomas Jefferson", { from: manager, gas: "100000000"});
    const ballot2 = await politicoin.showBallot.call(1);
    assert.equal(ballot2[0], "Thomas Jefferson");
    const ballotId = await politicoin.getHighestBallotId.call();
    assert.equal(ballotId, 1)
  });
  it("only a manager can create a ballot", async () => {
    const politicoin = await AdCoin.new();
      try {
        await politicoin.createBallot("George Washington", { from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("allows users to vote yes and no", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000" });
    await politicoin.whiteListAddresses([user1, user2], { from: manager, gas: "100000000"});
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
    await politicoin.castVote(0, true, { from: user1, gas: "100000000"});
    await politicoin.castVote(0, false, { from: user2, gas: "100000000"});
    const results = await politicoin.showBallot.call(0);
    const yesVotes = results[2].toNumber();
    const noVotes = results[3].toNumber();
    assert.equal(yesVotes, 500);
    assert.equal(noVotes, 1000);
  });
  it("tallies multiple yes votes", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000" });
    await politicoin.whiteListAddresses([user1, user2], { from: manager, gas: "100000000"});
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
    await politicoin.castVote(0, true, { from: user1, gas: "100000000"});
    await politicoin.castVote(0, true, { from: user2, gas: "100000000"});
    const results = await politicoin.showBallot.call(0);
    const yesVotes = results[2].toNumber();
    assert.equal(yesVotes, 1500);
  });
  it("only a whitelisted address can vote", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000" });
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
      try {
        await politicoin.castVote(0, true, { from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("locked address cannot vote", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000"});
    await politicoin.whiteListAddresses([user1, user2], { from: manager, gas: "100000000"});
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
    await politicoin.castVote(0, true, { from: user1, gas: "100000000"});
      try {
        await politicoin.castVote(0, false, { from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("manager can lock tokens", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.lockTokensMaster(user1, { from: manager, gas: "100000000"});
    const lockedTokens = await politicoin.showLockedTokens.call();
    assert.equal(lockedTokens[0], user1);
  });
  it("only a manager can lock tokens", async () => {
    const politicoin = await AdCoin.new();
      try {
        await politicoin.lockTokensMaster(user2, { from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("allows a transfer", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000"});
    await politicoin.transfer(user2, 250, {from: user1});
    const user2balance = await politicoin.balanceOf.call(user2);
    const user1balance = await politicoin.balanceOf.call(user1);
    assert.equal(user2balance, 1250);
    assert.equal(user1balance, 250);
  });
  it("locked tokens can't transfer", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000"});
    await politicoin.whiteListAddresses([user1, user2], { from: manager, gas: "100000000"});
    await politicoin.createBallot("George Washington", { from: manager, gas: "100000000"});
    await politicoin.castVote(0, true, { from: user1, gas: "100000000"});
      try {
        await politicoin.transfer(user2, 250, {from: user1});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
  it("manager can unlock tokens", async () => {
    const politicoin = await AdCoin.new();
    await politicoin.distribute([user1, user2], [500, 1000], { from: manager, gas: "100000000"});
    await politicoin.lockTokensMaster(user1, { from: manager, gas: "100000000"});
    await politicoin.lockTokensMaster(user2, { from: manager, gas: "100000000"});
    await politicoin.unlockAllTokens( { from: manager, gas: "100000000"});
    await politicoin.transfer(user2, 250, {from: user1});
    const user2balance = await politicoin.balanceOf.call(user2);
    const user1balance = await politicoin.balanceOf.call(user1);
    assert.equal(user2balance, 1250);
    assert.equal(user1balance, 250);
  });
  it("only a manager can unlock tokens", async () => {
    const politicoin = await AdCoin.new();
      try {
        await politicoin.unlockAllTokens({ from: user1, gas: "100000000"});
        assert(false);
      } catch (err) {
        assert(err);
      }
  });
});
