const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("DestoreModule", (m) => {
  // Deploy DeStoreToken
  const deStoreToken = m.contract("DestoreToken");

  // Deploy DeStore
  // Note: We're using the module's context to get the deployer's address
  const deStore = m.contract("Destore", [m.getAccount(1), deStoreToken]);

  return { deStoreToken, deStore };
});