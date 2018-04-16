var Migrations = artifacts.require("./Migrations.sol");
var Copyright = artifacts.require('./Copyright.sol');

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Copyright);
};
