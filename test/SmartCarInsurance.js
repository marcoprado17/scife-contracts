const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const smartCarInsuranceFactory = require('../ethereum/build/SmartCarInsuranceContractFactory.json');
const smartCarInsurance = require('../ethereum/build/SmartCarInsuranceContract.json');

let accounts;
let factory;
let smartCarInsuranceContractAddress;
let smartCarInsuranceContract;
let smartCarInsuranceContractAddress2;
let smartCarInsuranceContract2;

const initialContribution = web3.utils.toWei("0.01");
const refundValue = web3.utils.toWei("0.1");
const nMaxParticipants = 5;
const minVotePercentageToRefund = 25;

beforeEach(async () => {
    accounts = await web3.eth.getAccounts();

    factory = await new web3.eth.Contract(JSON.parse(smartCarInsuranceFactory.interface))
        .deploy({ data: smartCarInsuranceFactory.bytecode })
        .send({ from: accounts[0], gas: '2000000' });

    await factory.methods.createSmartCarInsuranceContract(
        "Abc",
        initialContribution,
        refundValue,
        nMaxParticipants,
        minVotePercentageToRefund
    ).send({
        from: accounts[0],
        gas: '1000000'
    });
    
    await factory.methods.createSmartCarInsuranceContract(
        "Abc",
        initialContribution,
        refundValue,
        nMaxParticipants,
        minVotePercentageToRefund
    ).send({
        from: accounts[0],
        gas: '1000000'
    });

    [smartCarInsuranceContractAddress, smartCarInsuranceContractAddress2] = await factory.methods.getDeployedContracts().call();
    smartCarInsuranceContract = await new web3.eth.Contract(
        JSON.parse(smartCarInsurance.interface),
        smartCarInsuranceContractAddress
    );
    smartCarInsuranceContract2 = await new web3.eth.Contract(
        JSON.parse(smartCarInsurance.interface),
    smartCarInsuranceContractAddress2
    );
});

describe('SmartCarInsurance', () => {
    it('deploys a SmartCarInsuranceContractFactory and a SmartCarInsuranceContract', () => {
        assert.ok(factory.options.address);
        assert.ok(smartCarInsuranceContract.options.address);
    });

    it('not accept new gps data from unregistered user', async () => {
        let throwError = false;
        try{
            await smartCarInsuranceContract.methods.pushGpsData(123, "abc").send({
                from: accounts[0],
                gas: '1000000'
            });
        }
        catch(err) {
            throwError = true;
        }
        assert(throwError, "Error should be hurled");
    });

    it('accept new gps data from registered user', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
        await smartCarInsuranceContract.methods.pushGpsData(123, "abc").send({
            from: accounts[0],
            gas: '1000000'
        });
    });

    it('not accept new meber with contribution below minimum', async () => {
        let throwError = false;
        try{
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[0],
                gas: '1000000',
                value: initialContribution/2
            });
        }
        catch(err) {
            throwError = true;
        }
        assert(throwError, "Error should be hurled");
    });

    it('accept new mebers with contribution equal minimum', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
    });

    it('cant join smart insurance contract more than once', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[0],
                gas: '1000000',
                value: initialContribution
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError, "Error should be hurled");
    });

    it('different accounts can join to the same smart car insurance contract', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[1],
            gas: '1000000',
            value: initialContribution
        });
    });

    it('smart insurance contract has a limit of members', async () => {
        for(let i = 0; i < nMaxParticipants; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[nMaxParticipants],
                gas: '1000000',
                value: initialContribution
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError, "Error should be hurled");
    });

    it('store in factory the contract of each member', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });

        let actual = await factory.methods.getMyContractAddresses().call({
            from: accounts[0],
        });
        let expected = [smartCarInsuranceContract.options.address];
        assert.deepEqual(actual, expected);

        await smartCarInsuranceContract2.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
        
        actual = await factory.methods.getMyContractAddresses().call({
            from: accounts[0],
        });
        expected = [smartCarInsuranceContract.options.address, smartCarInsuranceContract2.options.address];
        assert.deepEqual(actual, expected);
    });
});
