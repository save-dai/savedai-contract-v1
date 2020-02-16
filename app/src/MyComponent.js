import React from "react";

import {
  AccountData,
  ContractData,
  ContractForm,
} from "@drizzle/react-components";

import logo from "./logo.png";

export default ({ accounts }) => (
  <div className="App">
    <div className="section">
      <h2>Exercise SaveDAI And Get Back DAI</h2>
      <ContractForm contract="SaveDAI" method="exerciseOCDAI" labels={["SaveDAI Amount"]}/>
      <h2>Get SaveDAI</h2>
      <ContractForm contract="SaveDAI" method="mint" labels={["Recipient Address", "Dai Amount"]}/>
    </div>

  </div>
);
