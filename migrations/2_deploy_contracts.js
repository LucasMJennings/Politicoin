var ERC20 = artifacts.require("./libraries/erc20/ERC20.sol");
var ERC20Mintable = artifacts.require("./libraries/erc20/ERC20Mintable.sol");
var SafeMath = artifacts.require("./libraries/math/SafeMath.sol");
var Roles = artifacts.require("./libraries/roles/Roles.sol");
var MinterRole = artifacts.require("./libraries/roles/MinterRole.sol");
var LockedToken = artifacts.require("./LockedToken.sol");
var Politicoin = artifacts.require("./Politicoin.sol");
var AdCoin = artifacts.require("./AdCoin.sol");
var DonorCoin = artifacts.require("./DonorCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(LockedToken);
  deployer.deploy(ERC20);
  deployer.deploy(ERC20Mintable);
  deployer.deploy(Roles);
  deployer.deploy(MinterRole);
  deployer.deploy(Politicoin);
  deployer.deploy(AdCoin);
  deployer.deploy(DonorCoin);
};
