import web3 from './web3';
import SmartCarInsuranceContractFactory from './build/SmartCarInsuranceContractFactory.json';

const configs = require('./configs');

const instance = new web3.eth.Contract(
  JSON.parse(SmartCarInsuranceContractFactory.interface),
  configs.factoryAddress
);

export default instance;
