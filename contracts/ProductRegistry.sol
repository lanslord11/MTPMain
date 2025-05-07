// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ProductRegistry {
  
    enum GrainType {
        Wheat,
        Rice,
        Corn,
        Barley,
        Oats
    }

    struct Actor {
        bool exists;
        string name;         
        string role;         
        string metadataURI;  
    }


    struct BatchMetadata {
        bool exists;
        GrainType grainType;
        string variety;           
        uint256 harvestDate;      
        uint256 initialQuality;   
    }

    struct Batch {
        bool exists;
        address[] lineage;          
        BatchMetadata metadata;
        mapping(uint256 => string) environmentalLogs; 
        uint256 lineageCount; 
    }

    mapping(address => Actor) public actors;

    mapping(bytes32 => Batch) private batches; 

    event ActorRegistered(address indexed actor, string name, string role, string metadataURI);
    event ActorUpdated(address indexed actor, string name, string role, string metadataURI);

    event BatchRegistered(
        bytes32 indexed batchId,
        address[] lineage,
        GrainType grainType,
        string variety,
        uint256 harvestDate,
        uint256 initialQuality
    );

    event EnvironmentalLogAdded(bytes32 indexed batchId, uint256 indexed index, string logURI);

    modifier onlyRegisteredActor() {
        require(actors[msg.sender].exists, "Caller is not a registered actor");
        _;
    }

    function registerActor(address _actor, string calldata _name, string calldata _role, string calldata _metadataURI)
        external
    {
        require(!actors[_actor].exists, "Actor already registered");
        actors[_actor] = Actor({
            exists: true,
            name: _name,
            role: _role,
            metadataURI: _metadataURI
        });
        emit ActorRegistered(_actor, _name, _role, _metadataURI);
    }

    function updateActor(address _actor, string calldata _name, string calldata _role, string calldata _metadataURI)
        external
        onlyRegisteredActor
    {
        require(actors[_actor].exists, "Actor not registered");
        actors[_actor].name = _name;
        actors[_actor].role = _role;
        actors[_actor].metadataURI = _metadataURI;
        emit ActorUpdated(_actor, _name, _role, _metadataURI);
    }

    
    function registerBatch(
        bytes32 _batchId,
        address[] calldata _lineage,
        GrainType _grainType,
        string calldata _variety,
        uint256 _harvestDate,
        uint256 _initialQuality
    )
        external
        onlyRegisteredActor
    {
        require(!batches[_batchId].exists, "Batch already registered");
        require(_lineage.length > 0, "Empty lineage");
        
        for (uint256 i = 0; i < _lineage.length; i++) {
            require(actors[_lineage[i]].exists, "Lineage includes unregistered actor");
        }

        Batch storage b = batches[_batchId];
        b.exists = true;
        for (uint256 i = 0; i < _lineage.length; i++) {
            b.lineage.push(_lineage[i]);
        }
        b.lineageCount = _lineage.length;

        b.metadata.exists = true;
        b.metadata.grainType = _grainType;
        b.metadata.variety = _variety;
        b.metadata.harvestDate = _harvestDate;
        b.metadata.initialQuality = _initialQuality;

        emit BatchRegistered(_batchId, _lineage, _grainType, _variety, _harvestDate, _initialQuality);
    }

    
    function addEnvironmentalLog(bytes32 _batchId, uint256 _lineageIndex, string calldata _logURI)
        external
        onlyRegisteredActor
    {
        require(batches[_batchId].exists, "Batch does not exist");
        Batch storage b = batches[_batchId];
        require(_lineageIndex < b.lineageCount, "Invalid lineage index");

        
        b.environmentalLogs[_lineageIndex] = _logURI;
        emit EnvironmentalLogAdded(_batchId, _lineageIndex, _logURI);
    }

    
    function updateBatchQuality(bytes32 _batchId, uint256 _newQuality) external onlyRegisteredActor {
        require(batches[_batchId].exists, "Batch does not exist");
        batches[_batchId].metadata.initialQuality = _newQuality;
    }

    function isActorRegistered(address _actor) external view returns (bool) {
        return actors[_actor].exists;
    }

    function getActorInfo(address _actor) external view returns (string memory name, string memory role, string memory metadataURI) {
        require(actors[_actor].exists, "Actor not registered");
        Actor memory a = actors[_actor];
        return (a.name, a.role, a.metadataURI);
    }

    
    function isBatchRegistered(bytes32 _batchId) external view returns (bool) {
        return batches[_batchId].exists;
    }
    function getBatchLineage(bytes32 _batchId) external view returns (address[] memory) {
        require(batches[_batchId].exists, "Batch does not exist");
        return batches[_batchId].lineage;
    }

    
    function getBatchMetadata(bytes32 _batchId)
        external
        view
        returns (GrainType grainType, string memory variety, uint256 harvestDate, uint256 initialQuality)
    {
        require(batches[_batchId].exists, "Batch does not exist");
        Batch storage b = batches[_batchId];
        return (b.metadata.grainType, b.metadata.variety, b.metadata.harvestDate, b.metadata.initialQuality);
    }

    
    function getEnvironmentalLog(bytes32 _batchId, uint256 _lineageIndex) external view returns (string memory) {
        require(batches[_batchId].exists, "Batch does not exist");
        Batch storage b = batches[_batchId];
        require(_lineageIndex < b.lineageCount, "Invalid lineage index");
        return b.environmentalLogs[_lineageIndex];
    }
}
