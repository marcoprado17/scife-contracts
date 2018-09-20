pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    address[] public deployedContracts;

    function createSmartCarInsuranceContract(
        string contractName,
        uint initialContribution,
        uint monthlyContribution,
        uint refundValue,
        uint nMaxParticipants,
        uint minVotePercentageToRefund
    ) public {
        address newContractAddress = new SmartCarInsuranceContract(
            contractName,
            initialContribution,
            monthlyContribution,
            refundValue,
            nMaxParticipants,
            minVotePercentageToRefund, 
            msg.sender
        );
        deployedContracts.push(newContractAddress);
    }

    function getDeployedContracts() public view returns (address[]) {
        return deployedContracts;
    }
}

// // Este contrato será responsavel por fornecer o dia e mês a partir do unix timestamp do bloco
// contract DateUtilsContract {

// }

contract SmartCarInsuranceContract {
    string contractName;
    uint initialContribution;
    uint monthlyContribution;
    uint refundValue;
    uint nMaxParticipants;
    uint minVotePercentageToRefund;
    address creator;

    function SmartCarInsuranceContract(
        string _contractName,
        uint _initialContribution,
        uint _monthlyContribution,
        uint _refundValue,
        uint _nMaxParticipants,
        uint _minVotePercentageToRefund,
        address _creator
    ) public {
        contractName = _contractName;
        initialContribution = _initialContribution;
        monthlyContribution = _monthlyContribution;
        refundValue = _refundValue;
        nMaxParticipants = _nMaxParticipants;
        minVotePercentageToRefund = _minVotePercentageToRefund;
        creator = _creator;
    }
}
