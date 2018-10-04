const path = require('path');
const configsPath = path.resolve(__dirname, 'configs.json');
const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledFactory = require('./build/SmartCarInsuranceContractFactory.json');
const secrets = require('./secrets');
const fs = require('fs');

const provider = new HDWalletProvider(
  secrets.mnemonic,
  secrets.infuraUrl
);
const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();

  console.log('Attempting to deploy from account', accounts[0]);

  const result = await new web3.eth.Contract(
    JSON.parse(compiledFactory.interface)
  )
    .deploy({ data: compiledFactory.bytecode })
    .send({ gas: '2000000', from: accounts[0] });

  console.log('Contract deployed to', result.options.address);

  let configs = require(configsPath);
  configs.factoryAddress = result.options.address;
  fs.writeFileSync(configsPath, JSON.stringify(configs, null, 2), 'utf-8');
};

deploy();
