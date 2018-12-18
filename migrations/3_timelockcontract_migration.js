var multiTimelockTokenContract = artifacts.require("./MultiTimeLockTokenContract.sol");
var TudaToken = artifacts.require("./TudaToken.sol");

module.exports = function(deployer) {
  deployer.deploy(multiTimelockTokenContract, TudaToken.address);
};
