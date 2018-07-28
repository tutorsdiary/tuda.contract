var sendlockedtokencontract = artifacts.require("./SendLockedTokenContract.sol");
var TudaToken = artifacts.require("./TudaToken.sol");

var token = TudaToken.address;

module.exports = function(deployer) {
  deployer.deploy(sendlockedtokencontract, token);
};
