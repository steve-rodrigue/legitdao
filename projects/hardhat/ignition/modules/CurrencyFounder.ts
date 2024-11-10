// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CurrencyFounderModule = buildModule("CurrencyFounderModule", (m) => {
  const ins = m.contract("CurrencyFounder");
  return { ins };
});

export default CurrencyFounderModule;
