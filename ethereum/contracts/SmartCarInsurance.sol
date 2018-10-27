// Utilizando a versão 0.4.17 da linguagem Solidity
pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    // Array contendo os endereços ethereum de todos os contratos 
    // SmartCarInsuranceContract que SmartCarInsuranceContractFactory gerou
    address[] public deployedContracts;
    // Hash table para checagem rápida se certo endereço ethereum representa um 
    // um contrato SmartCarInsuranceContract deployado por SmartCarInsuranceContractFactory
    mapping(address => bool) public deployedContractsMapping;
    // Mapeia os contratos SmartCarInsuranceContract que cada usuário participa
    mapping(address => address[]) contractAddressesOfUsers;

    // Método que cria uma nova instância de SmartCarInsuranceContract
    function createSmartCarInsuranceContract(
        string name,
        uint initialContribution,
        uint refundValue,
        uint nMaxParticipants,
        uint minVotePercentageToRefund
    ) public {
        // Criando uma nova instância de um contrato SmartCarInsuranceContract
        address newContractAddress = new SmartCarInsuranceContract(
            name,
            initialContribution,
            refundValue,
            nMaxParticipants,
            minVotePercentageToRefund, 
            msg.sender
        );
        // Armazenando o contrato deployado em deployedContracts
        deployedContracts.push(newContractAddress);
        // Adicionando à hash table deployedContractsMapping o endereço do novo
        // contrato deployado
        deployedContractsMapping[newContractAddress] = true;
    }

    // Obtenção de deployedContracts
    function getDeployedContracts() public view returns (address[]) {
        return deployedContracts;
    }

    // Adiciona à contractAddressesOfUsers que userAddress agora faz parte
    // do contrato SmartCarInsuranceContract que chamou essa função (msg.sender)
    function userSignedToContract(address userAddress) public{
        // Garantindo que quem chamou userSignedToContract seja de fato um
        // contrato SmartCarInsuranceContract deployado por SmartCarInsuranceContractFactory
        require(deployedContractsMapping[msg.sender]);
        contractAddressesOfUsers[userAddress].push(msg.sender);
    }

    // Obtendo a array contendo os endereços dos contratos SmartCarInsuranceContract
    // que o usuário que chamou essa função participa
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
    }

    struct Request {
        string encodedData;
        address creatorAddress;
        mapping(address => bool) approvers;
        uint nApprovers;
        bool boConfirmed;
        uint unixTimestampOfBlock;
        bool refundMade;
    }

    Details public details;
    mapping(address => GpsData[]) public gpsDataByUserAddress;
    mapping(address => bool) public membersMapping;
    address[] public members;
    address public factoryAddress;
    Request[] public requests;
    
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
        uint l = gpsDataByUserAddress[msg.sender].length;
        if(l > 0){
            require(_creationUnixTimestamp > gpsDataByUserAddress[msg.sender][l-1].creationUnixTimestamp);
        }
        GpsData memory newGpsData = GpsData({
            blockUnixTimestamp: block.timestamp,
            creationUnixTimestamp: _creationUnixTimestamp,
            encryptedLatLong: _encryptedLatLong
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

    /*
        data represents the base64 encode of the below object:
        {
            unixTimesptampOfTheft: 1232143213,
            latTheft: 1.2231
            longTheft: 2.2314
            keysOfGpsData = [
                [122348763244, "secret"], # [unixTimestamp, key]
                [122348763244, "secret"],
                ...
            ]
        }
     */
    function createNewRefundRequest(string encodedData) public {
        require(membersMapping[msg.sender]);
        Request memory newRequest;
        newRequest.encodedData = encodedData;
        newRequest.creatorAddress = msg.sender;
        newRequest.boConfirmed = false;
        newRequest.nApprovers = 0;
        newRequest.unixTimestampOfBlock = block.timestamp;
        newRequest.refundMade = false;
        requests.push(newRequest);
    }

    function getMinApprovers() public view returns (uint) {
        uint multi = details.minVotePercentageToRefund * details.nParticipants;
        bool hasRemainder = true;
        if(multi % 100 == 0){
            hasRemainder = false;
        }
        uint minApprovers = multi / 100;
        if(hasRemainder){
            minApprovers++;
        }
        return minApprovers;
    }

    function approveRequest(uint requestIdx) public{
        require(membersMapping[msg.sender]);
        require(!requests[requestIdx].approvers[msg.sender]);
        requests[requestIdx].approvers[msg.sender] = true;
        requests[requestIdx].nApprovers++;
        uint minApprovers = getMinApprovers();
        if(
            requests[requestIdx].nApprovers >= minApprovers
            && address(this).balance >= details.refundValue
            && requests[requestIdx].boConfirmed
        ){
            requests[requestIdx].creatorAddress.send(details.refundValue);
            requests[requestIdx].refundMade = true;
        }
    }

    function getRefund(uint requestIdx) public {
        require(requests[requestIdx].creatorAddress == msg.sender);
        require(requests[requestIdx].boConfirmed);
        uint minApprovers = getMinApprovers();
        require(requests[requestIdx].nApprovers >= minApprovers);
        require(address(this).balance >= details.refundValue);
        requests[requestIdx].creatorAddress.transfer(details.refundValue);
        requests[requestIdx].refundMade = true;
    }

    function getLengthOfRequests() public view returns(uint) {
        return requests.length;
    }

    function addressToBytes(address _addr) public pure returns(bytes) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint(value[i + 12] & 0x0f)];
        }
        return str;
    }

    function confirmBO(uint requestIdx) public {
        require(!requests[requestIdx].boConfirmed);
        bytes memory validBoSenderAddress = "0x5e924ac15745b75e0d23afd68d1bb1adb8f43689";
        bytes memory senderAddress = addressToBytes(msg.sender);
        bool validSender = true;
        for(uint i = 0; i < validBoSenderAddress.length; i++){
            if(validBoSenderAddress[i] != senderAddress[i]){
                validSender = false;
            }
        }
        require(validSender);
        requests[requestIdx].boConfirmed = true;
    }

    // function binarySearch(address userAddress, uint targetValue, uint low, uint high) public view returns (uint){
    //     if(high < low){
    //         return low;
    //     }
    //     uint mid = (low+high)/2;
    //     if(gpsDataByUserAddress[userAddress][mid].creationUnixTimestamp > targetValue){
    //         return binarySearch(userAddress, targetValue, low, mid-1);
    //     }
    //     else if(gpsDataByUserAddress[userAddress][mid].creationUnixTimestamp < targetValue){
    //         return binarySearch(userAddress, targetValue, mid+1, high);
    //     }
    //     else{
    //         return mid;
    //     }
    // }

    function getGpsDataIndex(address userAddress, uint creationUnixTimestamp) public view returns(uint){
        if(gpsDataByUserAddress[userAddress].length == 0){
            return 0;
        }
        if(creationUnixTimestamp <= gpsDataByUserAddress[userAddress][0].creationUnixTimestamp){
            return 0;
        }
        if(creationUnixTimestamp >= gpsDataByUserAddress[userAddress][gpsDataByUserAddress[userAddress].length-1].creationUnixTimestamp){
            return gpsDataByUserAddress[userAddress].length-1;
        }
        uint low = 0;
        uint high = gpsDataByUserAddress[userAddress].length-1;
        while (low <= high) {
            uint mid = (low + high) / 2;
            if(gpsDataByUserAddress[userAddress][mid].creationUnixTimestamp > creationUnixTimestamp){
                high = mid - 1;
            }
            else if (gpsDataByUserAddress[userAddress][mid].creationUnixTimestamp < creationUnixTimestamp){
                low = mid + 1;
            }
            else {
                return mid;
            }
        }
        return low;
    }

    function iAlreadyApproved(uint requestIdx) public view returns (bool) {
        require(membersMapping[msg.sender]);
        return requests[requestIdx].approvers[msg.sender];
    }
}
