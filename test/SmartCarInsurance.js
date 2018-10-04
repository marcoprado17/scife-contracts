const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const secrets = require('../ethereum/secrets');
const web3 = new Web3(ganache.provider({
    mnemonic: secrets.mnemonic
}));

const smartCarInsuranceFactory = require('../ethereum/build/SmartCarInsuranceContractFactory.json');
const smartCarInsurance = require('../ethereum/build/SmartCarInsuranceContract.json');

let accounts;
let factory;
let smartCarInsuranceContractAddress;
let smartCarInsuranceContract;
let smartCarInsuranceContractAddress2;
let smartCarInsuranceContract2;

const initialContribution = web3.utils.toWei("0.03");
const refundValue = web3.utils.toWei("0.1");
const nMaxParticipants = 5;
const minVotePercentageToRefund = 25;
const newRefundRequestEncodedData = "Abc";

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
        gas: '2500000'
    });
    
    await factory.methods.createSmartCarInsuranceContract(
        "Abc",
        initialContribution,
        refundValue,
        nMaxParticipants,
        minVotePercentageToRefund
    ).send({
        from: accounts[0],
        gas: '2500000'
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
        assert.equal((await smartCarInsuranceContract.methods.details().call()).nParticipants, nMaxParticipants);
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

    it('cant create new refund request if isnt member', async () => {
        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).call({
                from: accounts[0],
                gas: '1000000'
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError);
    });

    it('can create new refund request if is member', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });

        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        let lengthOfRequests = await smartCarInsuranceContract.methods.getLengthOfRequests().call();
        assert.equal(lengthOfRequests, 1);
        let request = await smartCarInsuranceContract.methods.requests(0).call();
        assert.equal(request.encodedData, newRefundRequestEncodedData);
        assert.equal(request.creatorAddress, accounts[0]);
        assert.equal(request.nApprovers, 0);
        assert.equal(request.boConfirmed, false);
    });

    it('cant support request approval of no members', async () => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });

        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.approveRequest(0).send({
                from: accounts[1],
                gas: '1000000'
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError);
    });

    it('can support request approval of members', async () => {
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

        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
    });

    it('cant support request approval of a member more than once', async () => {
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

        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });

        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.approveRequest(0).send({
                from: accounts[1],
                gas: '1000000'
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError);
    });

    it('only accounts[5] can approve bo', async() => {
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[0],
            gas: '1000000',
            value: initialContribution
        });
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        let request = await smartCarInsuranceContract.methods.requests(0).call();
        assert(!request.boConfirmed);

        let throwError = false;
        try {
            await smartCarInsuranceContract.methods.confirmBO(0).send({
                from: accounts[2],
                gas: '1000000'
            });
        }
        catch(err){
            throwError = true;
        }
        assert(throwError);

        await smartCarInsuranceContract.methods.confirmBO(0).send({
            from: accounts[5],
            gas: '1000000'
        });
        request = await smartCarInsuranceContract.methods.requests(0).call();
        assert(request.boConfirmed);
    });

    it('cant liberate refund when nAppovers < nMinApprovers', async () => {
        for(let i = 0; i < nMaxParticipants; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.confirmBO(0).send({
            from: accounts[5],
            gas: '1000000'
        });

        let initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
        let account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(initialAccount0Balance == account0Balance);
    });

    it('cant liberate refund when new approval and bo isnt confirmed', async () => {
        for(let i = 0; i < nMaxParticipants; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });

        let initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[2],
            gas: '1000000'
        });

        let account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(initialAccount0Balance = account0Balance);
    });

    it('cant liberate refund when new approval and contract balance isnt ok', async () => {
        for(let i = 0; i < 3; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.confirmBO(0).send({
            from: accounts[5],
            gas: '1000000'
        });

        let initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[2],
            gas: '1000000'
        });

        let account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(account0Balance == initialAccount0Balance);
    });

    it('liberate refund when new approval and contract balance is ok', async () => {
        for(let i = 0; i < nMaxParticipants; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.confirmBO(0).send({
            from: accounts[5],
            gas: '1000000'
        });

        let initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[2],
            gas: '1000000'
        });

        let account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(account0Balance > initialAccount0Balance);
    });

    it('liberate refund when has approvals, bo, money and user activate get refund method', async () => {
        for(let i = 0; i < 3; i++){
            await smartCarInsuranceContract.methods.enterContract().send({
                from: accounts[i],
                gas: '1000000',
                value: initialContribution
            });
        }
        await smartCarInsuranceContract.methods.createNewRefundRequest(newRefundRequestEncodedData).send({
            from: accounts[0],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.confirmBO(0).send({
            from: accounts[5],
            gas: '1000000'
        });

        let initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[1],
            gas: '1000000'
        });
        await smartCarInsuranceContract.methods.approveRequest(0).send({
            from: accounts[2],
            gas: '1000000'
        });

        let account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(account0Balance == initialAccount0Balance);

        initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.enterContract().send({
            from: accounts[3],
            gas: '1000000',
            value: initialContribution
        });
        account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(account0Balance == initialAccount0Balance);

        initialAccount0Balance = await web3.eth.getBalance(accounts[0]);
        await smartCarInsuranceContract.methods.getRefund(0).send({
            from: accounts[0],
            gas: '1000000'
        });
        account0Balance = await web3.eth.getBalance(accounts[0]);
        assert(account0Balance > initialAccount0Balance);
    });
});
