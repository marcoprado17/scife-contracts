import web3 from './web3';
import SmartCarInsuranceContractFactory from './build/SmartCarInsuranceContractFactory.json';

const fs = require('fs');
const configs = JSON.parse(fs.readFileSync('configs.json'))

const instance = new web3.eth.Contract(
  JSON.parse(SmartCarInsuranceContractFactory.interface),
  configs.factoryAddress
);

export default instance;
