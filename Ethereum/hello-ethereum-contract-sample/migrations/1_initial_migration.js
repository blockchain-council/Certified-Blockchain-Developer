var Migrations = artifacts.require("./Migrations.sol");
var HelloEth = artifacts.require('./HelloEth.sol');
module.exports = function(deployer) {
  deployer.deploy(Migrations);
deployer.deploy(HelloEth);
};
