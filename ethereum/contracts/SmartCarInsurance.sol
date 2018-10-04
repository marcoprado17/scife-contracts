pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    address[] public deployedContracts;
    mapping(address => bool) public deployedContractsMapping;
    mapping(address => address[]) contractAddressesOfUsers;

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
        deployedContractsMapping[newContractAddress] = true;
    }

    function getDeployedContracts() public view returns (address[]) {
        return deployedContracts;
    }

    function userSignedToContract(address userAddress) public{
        require(deployedContractsMapping[msg.sender]);
        contractAddressesOfUsers[userAddress].push(msg.sender);
    }

    function getMyContractAddresses() public view returns (address[]){
        return contractAddressesOfUsers[msg.sender];
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
    mapping(address => bool) public membersMapping;
    address[] public members;
    address public factoryAddress;
    
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
        factoryAddress = msg.sender;
    }

    function pushGpsData(uint _creationUnixTimestamp, string _encryptedLatLong) public {
        require(membersMapping[msg.sender]);
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
        require(msg.value == details.initialContribution);
        require(!membersMapping[msg.sender]);
        require(members.length < details.nMaxParticipants);
        details.nParticipants++;
        membersMapping[msg.sender] = true;
        members.push(msg.sender);
        SmartCarInsuranceContractFactory smartCarInsuranceContractFactory = SmartCarInsuranceContractFactory(factoryAddress);
        smartCarInsuranceContractFactory.userSignedToContract(msg.sender);
    }

    function getMembers() public view returns (address[]) {
        return members;
    }
}
