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
      <ContractForm contract="SaveDAI" method="exerciseOCDAI" labels={["Dai Amount"]}/>
      <h2>Get SaveDAI</h2>
      <ContractForm contract="SaveDAI" method="mint" labels={["Recipient Address", "Dai Amount"]}/>
    </div>
    <div className="section">
      <h2>SimpleStorage</h2>
      <p>
        This shows a simple ContractData component with no arguments, along with
        a form to set its value.
      </p>
      <p>
        <strong>Stored Value: </strong>
        <ContractData contract="SimpleStorage" method="storedData" />
      </p>
      <ContractForm contract="SimpleStorage" method="set" />
    </div>
  </div>
);
