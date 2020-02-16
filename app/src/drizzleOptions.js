import Web3 from "web3";
//import SimpleStorage from "./contracts/SimpleStorage.json";
//import ComplexStorage from "./contracts/ComplexStorage.json";
// import TutorialToken from "./contracts/TutorialToken.json";


const options = {
  contracts: [],
  //contracts: [SimpleStorage, ComplexStorage, TutorialToken],
  events: {
    //SimpleStorage: ["StorageSet"],
  },
  polls: {
    accounts: 1500,
  },
};

export default options;
