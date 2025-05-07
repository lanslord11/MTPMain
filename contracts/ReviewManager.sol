// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ProductRegistryInterface {
    function isActorRegistered(address _actor) external view returns (bool);
    function isBatchRegistered(bytes32 _batchId) external view returns (bool);
    function getBatchLineage(bytes32 _batchId) external view returns (address[] memory);
}
 interface ReputationManagerInterface {
    function processIntermediateReview(
        bytes32 batchId,
        address reviewedActor,
        address reviewerActor,
        uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore
    ) external;

    function processFinalReview(
        bytes32 batchId,
        uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore
    ) external;
}
contract ReviewManager {
    ProductRegistryInterface public productRegistry;
    ReputationManagerInterface public reputationManager;

    mapping(bytes32 => bool) public finalReviewSubmitted;


    event IntermediateReviewSubmitted(bytes32 indexed batchId, address indexed reviewer, address indexed reviewedActor, uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore);
    event FinalReviewSubmitted(bytes32 indexed batchId, address indexed submitter, uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore);

    constructor(address _productRegistry, address _reputationManager) {
        productRegistry = ProductRegistryInterface(_productRegistry);
        reputationManager = ReputationManagerInterface(_reputationManager);
    }



    modifier onlyRegisteredActor() {
        require(productRegistry.isActorRegistered(msg.sender), "Caller not registered as an actor");
        _;
    }

    function submitIntermediateReview(
        bytes32 batchId,
        address reviewedActor,
        uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore
    )
        external
        onlyRegisteredActor
    {
        require(productRegistry.isBatchRegistered(batchId), "Invalid batch");

        address[] memory lineage = productRegistry.getBatchLineage(batchId);

        require(_isValidIntermediateReviewOrder(lineage, reviewedActor, msg.sender), "Invalid review order");

        reputationManager.processIntermediateReview(batchId, reviewedActor,msg.sender, Q, P, T, S, Rscore);

        emit IntermediateReviewSubmitted(batchId, msg.sender, reviewedActor, Q, P, T, S, Rscore);
    }

    function submitFinalReview(
        bytes32 batchId,
        uint256 Q, uint256 P, uint256 T, uint256 S, uint256 Rscore
    )
        external
    {
        require(productRegistry.isBatchRegistered(batchId), "Invalid batch");
        require(!finalReviewSubmitted[batchId], "Final review already submitted");

        finalReviewSubmitted[batchId] = true;

        reputationManager.processFinalReview(batchId, Q, P, T, S, Rscore);

        emit FinalReviewSubmitted(batchId, msg.sender, Q, P, T, S, Rscore);
    }

    function _isValidIntermediateReviewOrder(
        address[] memory lineage,
        address reviewedActor,
        address reviewer
    )
        internal
        pure
        returns (bool)
    {
        int256 reviewedIndex = -1;
        int256 reviewerIndex = -1;

        for (uint256 i = 0; i < lineage.length; i++) {
            if (lineage[i] == reviewedActor) {
                reviewedIndex = int256(i);
            }
            if (lineage[i] == reviewer) {
                reviewerIndex = int256(i);
            }
        }

        if (reviewedIndex >= 0 && reviewerIndex >= 0 && reviewerIndex > reviewedIndex) {
            return true;
        } else {
            return false;
        }
    }
}
