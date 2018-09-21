pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    address[] public deployedContracts;

    function createSmartCarInsuranceContract(
        string name,
        uint initialContribution,
        uint monthlyContribution,
        uint refundValue,
        uint nMaxParticipants,
        uint minVotePercentageToRefund
    ) public {
        address newContractAddress = new SmartCarInsuranceContract(
            name,
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
    struct Details {
        string name;
        uint initialContribution;
        uint monthlyContribution;
        uint refundValue;
        uint nMaxParticipants;
        uint minVotePercentageToRefund;
        address creatorId;
        uint nParticipants;
    }
    
    struct GpsLocation {
        uint blockNumber;
        uint timestamp;
        string lat;
        string long;
    }

    Details public details;
    mapping(address => GpsLocation[]) public gpsLocationsByUserAddress;
    
    function SmartCarInsuranceContract(
        string _name,
        uint _initialContribution,
        uint _monthlyContribution,
        uint _refundValue,
        uint _nMaxParticipants,
        uint _minVotePercentageToRefund,
        address _creatorId
    ) public {
        details = Details({
            name: _name,
            initialContribution: _initialContribution,
            monthlyContribution: _monthlyContribution,
            refundValue: _refundValue,
            nMaxParticipants: _nMaxParticipants,
            minVotePercentageToRefund: _minVotePercentageToRefund,
            creatorId: _creatorId,
            nParticipants: 0
        });
    }

    function addGpsLocation(string _lat, string _long) public {
        GpsLocation memory newGpsLocation = GpsLocation({
            blockNumber: 1,
            timestamp: 1,
            lat: _lat,
            long: _long
        });

        gpsLocationsByUserAddress[msg.sender].push(newGpsLocation);
    }
}
