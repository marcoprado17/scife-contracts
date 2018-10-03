pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    address[] public deployedContracts;

    function createSmartCarInsuranceContract(
        string name,
        uint initialContribution,
        uint refundValue,
        uint nMaxParticipants,
        uint minVotePercentageToRefund
    ) public {
        address newContractAddress = new SmartCarInsuranceContract(
            name,
            initialContribution,
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

contract SmartCarInsuranceContract {
    struct Details {
        string name;
        uint initialContribution;
        uint refundValue;
        uint nMaxParticipants;
        uint minVotePercentageToRefund;
        address creatorId;
        uint nParticipants;
    }
    
    struct GpsData {
        uint blockUnixTimestamp;
        uint creationUnixTimestamp;
        string encryptedLatLong;
        string key;
    }

    Details public details;
    mapping(address => GpsData[]) public gpsDataByUserAddress;
    mapping(address => bool) public members;
    
    function SmartCarInsuranceContract(
        string _name,
        uint _initialContribution,
        uint _refundValue,
        uint _nMaxParticipants,
        uint _minVotePercentageToRefund,
        address _creatorId
    ) public {
        details = Details({
            name: _name,
            initialContribution: _initialContribution,
            refundValue: _refundValue,
            nMaxParticipants: _nMaxParticipants,
            minVotePercentageToRefund: _minVotePercentageToRefund,
            creatorId: _creatorId,
            nParticipants: 0
        });
    }

    function pushGpsData(uint _creationUnixTimestamp, string _encryptedLatLong) public {
        GpsData memory newGpsData = GpsData({
            blockUnixTimestamp: block.timestamp,
            creationUnixTimestamp: _creationUnixTimestamp,
            encryptedLatLong: _encryptedLatLong,
            key: ""
        });

        gpsDataByUserAddress[msg.sender].push(newGpsData);
    }

    function getLengthOfGpsData(address _address) public view returns(uint) {
        return gpsDataByUserAddress[_address].length;
    }

    function enterContract() public payable{
        require(msg.value >= details.initialContribution);
        require(!members[msg.sender]);
        members[msg.sender] = true;
    }
}
