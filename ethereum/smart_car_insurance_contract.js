import web3 from './web3';
import SmartCarInsuranceContract from './build/SmartCarInsuranceContract.json';

export default address => {
  return new web3.eth.Contract(JSON.parse(SmartCarInsuranceContract.interface), address);
};
