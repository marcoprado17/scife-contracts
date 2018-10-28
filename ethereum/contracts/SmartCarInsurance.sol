// Utilizando a versão 0.4.17 da linguagem Solidity
pragma solidity ^0.4.17;

contract SmartCarInsuranceContractFactory {
    // Array contendo os endereços ethereum de todos os contratos 
    // SmartCarInsuranceContract que SmartCarInsuranceContractFactory 
    // gerou
    address[] public deployedContracts;
    // Hash table para checagem rápida se certo endereço 
    // ethereum representa um contrato SmartCarInsuranceContract 
    // deployado por SmartCarInsuranceContractFactory
    mapping(address => bool) public deployedContractsMapping;
    // Mapeia os contratos SmartCarInsuranceContract que cada 
    // usuário participa
    mapping(address => address[]) contractAddressesOfUsers;

    // Método que cria uma nova instância de SmartCarInsuranceContract
    function createSmartCarInsuranceContract(
        string name,
        uint initialContribution,
        uint refundValue,
        uint nMaxParticipants,
        uint minVotePercentageToRefund
    ) public {
        // Criando uma nova instância de um contrato 
        // SmartCarInsuranceContract
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
        // Adicionando à hash table deployedContractsMapping o 
        // endereço do novo contrato deployado
        deployedContractsMapping[newContractAddress] = true;
    }

    // Obtenção de deployedContracts
    function getDeployedContracts() public view returns (address[]) {
        return deployedContracts;
    }

    // Adiciona à contractAddressesOfUsers que userAddress agora faz 
    // parte do contrato SmartCarInsuranceContract que chamou essa 
    // função (msg.sender)
    function userSignedToContract(address userAddress) public{
        // Garantindo que quem chamou userSignedToContract seja de 
        // fato um contrato SmartCarInsuranceContract deployado 
        // por SmartCarInsuranceContractFactory
        require(deployedContractsMapping[msg.sender]);
        contractAddressesOfUsers[userAddress].push(msg.sender);
    }

    // Obtendo a array contendo os endereços dos contratos 
    // SmartCarInsuranceContract que o usuário que chamou essa 
    // função participa
    function getMyContractAddresses() public view returns (address[]){
        return contractAddressesOfUsers[msg.sender];
    }
}

contract SmartCarInsuranceContract {
    // Definindo a struct Details, tal struct armazena 
    // os principais dados do contrato
    struct Details {
        // Nome do contrato
        string name;
        // Contribuição inicial para participar do contrato
        uint initialContribution;
        // Valor do reembolso em caso de furto e roubo
        uint refundValue;
        // Número máximo de participantes
        uint nMaxParticipants;
        // Percentagem mínima de votos para liberar
        // o reembolso de caso de roubo ou furto
        uint minVotePercentageToRefund;
        // Endereço ethereum do criador desse contrato
        address creatorId;
        // Número de participantes do contrato
        uint nParticipants;
    }

    // Definindo a struct GpsData, tal struct armazena
    // uma amostra dos dados de gps de um usuário do contrato
    struct GpsData {
        // Unix timestamp do bloco ethereum que recebeu 
        // tal GpsData
        uint blockUnixTimestamp;
        // Tempo em que tal amostra foi colhida, esse valor
        // é enviado pelo usuário
        uint creationUnixTimestamp;
        // String encriptada contendo a latitude e longitude 
        // dessa amostra de sinal gps
        string encryptedLatLong;
    }

    // Definindo a struct Request, tal struct representa
    // uma requisição de reembolso criado por um usuário
    // do contrato
    struct Request {
        // String base64 encoded contendo um json com as informações
        // necessárias para a requisição:
        // {
        //     unixTimesptampOfTheft: 1232143213,
        //     latTheft: 1.2231
        //     longTheft: 2.2314
        //     keysOfGpsData = [
        //         [122348763244, "secret"], # [unixTimestamp, key]
        //         [122348763244, "secret"],
        //         ...
        //     ]
        // }
        string encodedData;
        // Endereço ethereum de quem criou a requisição de reembolso
        address creatorAddress;
        // Hash table que mapeia o endereço ethereum de quem aprovou
        // tal requisição de reembolso
        mapping(address => bool) approvers;
        // Número de usuários que aprovaram tal requisição de 
        // reembolso
        uint nApprovers;
        // Bool que indica se tal requisição de reembolso foi
        // aprovada pela polícia
        bool boConfirmed;
        // Unix timestamp do bloco ethereum que recebeu essa
        // nova requisição de reembolso
        uint unixTimestampOfBlock;
        // Bool que indica se o reembolso já foi efetuado ou não
        bool refundMade;
    }

    // Detalhes desse contrato de seguro automotivo
    Details public details;
    // Hash table que armazena os dados de gps de cada
    // membro do contrato
    mapping(address => GpsData[]) public gpsDataByUserAddress;
    // Hash table que armazena o endereço ethereum dos membros
    // do contrato
    mapping(address => bool) public membersMapping;
    // Array com o endereço ethereum de todos os membros do contrato
    address[] public members;
    // Endereço ethereum do contrato SmartCarInsuranceContractFactory
    // que deu origem a este contrato
    address public factoryAddress;
    // Array contento todas as requisições de reembolso feitas
    // nesse contrato
    Request[] public requests;
    
    // Contrutor de SmartCarInsuranceContract. Serve para criar
    // uma nova instância deste contrato
    function SmartCarInsuranceContract(
        string _name,
        uint _initialContribution,
        uint _refundValue,
        uint _nMaxParticipants,
        uint _minVotePercentageToRefund,
        address _creatorId
    ) public {
        // Garantindo alguns requisitos básicos para criação do contrato
        require(_initialContribution > 0);
        require(_refundValue > 0);
        require(_nMaxParticipants > 0);
        require(_minVotePercentageToRefund >= 0 && 
        _minVotePercentageToRefund <= 100);
        // Criando os detalhes desse contrato
        details = Details({
            name: _name,
            initialContribution: _initialContribution,
            refundValue: _refundValue,
            nMaxParticipants: _nMaxParticipants,
            minVotePercentageToRefund: _minVotePercentageToRefund,
            creatorId: _creatorId,
            nParticipants: 0
        });
        // Atualizando o endereço de quem criou a instância desse contrato
        factoryAddress = msg.sender;
    }

    // Método que adiciona um novo GpsData de um membro do contrato
    function pushGpsData(
        uint _creationUnixTimestamp, 
        string _encryptedLatLong) public {
        // Garantindo que quem chamou esse método seja um membro do contrato
        require(membersMapping[msg.sender]);
        uint l = gpsDataByUserAddress[msg.sender].length;
        if(l > 0){
            // Garantindo que unix timestamp fornecido pelo gps
            // seja maior do que o timestamp da última amostra
            // de sinal gps
            require(_creationUnixTimestamp > 
                gpsDataByUserAddress[msg.sender][l-1].creationUnixTimestamp);
        }
        // Criando uma nova instância de GpsData
        GpsData memory newGpsData = GpsData({
            blockUnixTimestamp: block.timestamp,
            creationUnixTimestamp: _creationUnixTimestamp,
            encryptedLatLong: _encryptedLatLong
        });

        // Adicionando a nova instância de GpsData criada para
        // a hash table gpsDataByUserAddress
        gpsDataByUserAddress[msg.sender].push(newGpsData);
    }

    // Método para a obtenção do comprimento da array que armazena
    // os dados de gps de um usuário específico
    function getLengthOfGpsData(address _address) 
    public view returns(uint) {
        return gpsDataByUserAddress[_address].length;
    }

    // Método que um possível membro do contrato chama para participar
    // do contrato de seuro automotivo em questão
    function enterContract() public payable{
        // Garantindo que o possível membro envie, ao chamar essa
        // função, um valor igual a contribuição inicial estabelecida
        // no momento em que esse contrato foi gerado
        require(msg.value == details.initialContribution);
        // Garantindo que quem chamou essa função não seja
        // membro do contrato ainda
        require(!membersMapping[msg.sender]);
        // Garantindo que o contrato em questão ainda não excederá
        // o número máximo de participantes
        require(members.length < details.nMaxParticipants);
        // Incrmentando o número de participantes
        details.nParticipants++;
        // Adicionando o novo membro à membersMapping e members
        membersMapping[msg.sender] = true;
        members.push(msg.sender);
        // Informando a SmartCarInsuranceContractFactory que msg.sender
        // agora é um membro deste contrato
        SmartCarInsuranceContractFactory smartCarInsuranceContractFactory = 
            SmartCarInsuranceContractFactory(factoryAddress);
        smartCarInsuranceContractFactory.userSignedToContract(msg.sender);
    }

    // Obtendo a array com os endereços ethereum dos membros deste contrato
    function getMembers() public view returns (address[]) {
        return members;
    }

    // Método chamado para a criação de uma nova requisição de reembolso
    /*
        encodedData representa a base64 encode do objeto abaixo:
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
        // Garantindo que quem chamou esse método (msg.sender)
        // seja um membro do contrato
        require(membersMapping[msg.sender]);
        // Criando uma nova instância da struct Request com
        // os devidos dados
        Request memory newRequest;
        newRequest.encodedData = encodedData;
        newRequest.creatorAddress = msg.sender;
        newRequest.boConfirmed = false;
        newRequest.nApprovers = 0;
        newRequest.unixTimestampOfBlock = block.timestamp;
        newRequest.refundMade = false;
        // Adicionando a instância de request criada à
        // array requests
        requests.push(newRequest);
    }

    // Obtendo o número mínimo de membros que devem aprovar
    // uma requisição de reembolso para ela ser liberada
    function getMinApprovers() public view returns (uint) {
        // Retornando 0 caso details.minVotePercentageToRefund == 0
        if(details.minVotePercentageToRefund == 0) {
            return 0;
        }
        // Retornando ceil de
        // details.minVotePercentageToRefund*details.nParticipants/100
        // caso contrário
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

    // Método que um usuário chama para aprovar determinada
    // requisição de reembolso
    function approveRequest(uint requestIdx) public{
        // Garantindo que msg.sender seja um membro do contrato
        require(membersMapping[msg.sender]);
        // Garantindo que msg.sender não tenha aprovado tal
        // requisão antes
        require(!requests[requestIdx].approvers[msg.sender]);
        // Adicionando aos aprovadores da requisição o endereço
        // de msg.sender
        requests[requestIdx].approvers[msg.sender] = true;
        // Aumentando o número de pessoas que aprovaram
        // tal requisição
        requests[requestIdx].nApprovers++;
        // Efetuando o reembolso caso os três requisitos abaxo
        // sejam atendidos
        // a) O número de membros aprovadores do reembolso seja 
        // maior ou igual ao mínimo requerido;
        // b) O contrato possua uma quantia de ethereum maior ou igual
        // ao valor do reembolso;
        // c) O boletim de ocorrência de furto ou roubo já tenha
        // sido confirmado pela polícia.
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

    // Liberando o reembolso caso todos os requisitos
    // para liberação do reembolso estejam etendidos
    function getRefund(uint requestIdx) public {
        require(requests[requestIdx].creatorAddress == msg.sender);
        require(requests[requestIdx].boConfirmed);
        uint minApprovers = getMinApprovers();
        require(requests[requestIdx].nApprovers >= minApprovers);
        require(address(this).balance >= details.refundValue);
        requests[requestIdx].creatorAddress.transfer(details.refundValue);
        requests[requestIdx].refundMade = true;
    }

    // Obtendo o comprimento da array requests
    function getLengthOfRequests() public view returns(uint) {
        return requests.length;
    }

    // Função que converte um address para bytes
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

    // Função que confirma se o BO de furto ou roubo
    // de uma determinada requisição de reembolso foi feito
    // com sucesso
    function confirmBO(uint requestIdx) public {
        // Garantindo que o BO ainda não tenha sido confirmado
        require(!requests[requestIdx].boConfirmed);
        // Garantindo que msg.sender == 
        // "0x5e924ac15745b75e0d23afd68d1bb1adb8f43689"
        bytes memory validBoSenderAddress = 
        "0x5e924ac15745b75e0d23afd68d1bb1adb8f43689";
        bytes memory senderAddress = addressToBytes(msg.sender);
        bool validSender = true;
        for(uint i = 0; i < validBoSenderAddress.length; i++){
            if(validBoSenderAddress[i] != senderAddress[i]){
                validSender = false;
            }
        }
        require(validSender);
        // Confirmando o BO
        requests[requestIdx].boConfirmed = true;
    }

    // Obtendo o indice do GpsData na array 
    // gpsDataByUserAddress[userAddress] que foi criado
    // o mais proximo possível de creationUnixTimestamp
    function getGpsDataIndex(
        address userAddress, 
        uint creationUnixTimestamp) public view returns(uint){
        if(gpsDataByUserAddress[userAddress].length == 0){
            return 0;
        }
        if(creationUnixTimestamp <= 
        gpsDataByUserAddress[userAddress][0].creationUnixTimestamp){
            return 0;
        }
        if(
            creationUnixTimestamp >= 
            gpsDataByUserAddress[userAddress]
            [gpsDataByUserAddress[userAddress].length-1]
            .creationUnixTimestamp){
            return gpsDataByUserAddress[userAddress].length-1;
        }
        // Efetuando uma busca binária para obtenção do indice
        // de GpsData com creationUnixTimestamp mais próximo
        // do desejado
        uint low = 0;
        uint high = gpsDataByUserAddress[userAddress].length-1;
        while (low <= high) {
            uint mid = (low + high) / 2;
            if(gpsDataByUserAddress[userAddress]
            [mid].creationUnixTimestamp > 
            creationUnixTimestamp){
                high = mid - 1;
            }
            else if (gpsDataByUserAddress[userAddress][mid]
            .creationUnixTimestamp < creationUnixTimestamp){
                low = mid + 1;
            }
            else {
                return mid;
            }
        }
        return low;
    }

    // Método que retorna um bool indicando se msg.sender
    // já aprovou ou não o a requisição de índice requestIdx
    function iAlreadyApproved(uint requestIdx) public view returns (bool) {
        require(membersMapping[msg.sender]);
        return requests[requestIdx].approvers[msg.sender];
    }
}
