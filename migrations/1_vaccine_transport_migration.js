const VaccineTransport = artifacts.require("SupplyChain");

module.exports = function (deployer) {
  deployer.deploy(VaccineTransport);
};
