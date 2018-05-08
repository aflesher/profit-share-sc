var ProfitShare = artifacts.require("ProfitShare"); 
module.exports = function(deployer) {
  deployer.deploy(ProfitShare, [], [], []);
};