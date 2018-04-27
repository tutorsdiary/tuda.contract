var TudaToken = artifacts.require("./TudaToken.sol");

module.exports = function(deployer) {
  deployer.deploy(TudaToken);
};
