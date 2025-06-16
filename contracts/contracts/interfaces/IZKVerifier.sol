// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IZKVerifier
 * @dev Interface for the ZKVerifier contract that verifies zero-knowledge proofs for certificates
 */
interface IZKVerifier {
    /**
     * @dev Struct containing information about a registered verifier circuit
     */
    struct VerifierCircuit {
        uint256 id;
        string name;
        string description;
        address verifierContract;
        bool isActive;
    }
    
    /**
     * @dev Struct containing proof data
     */
    struct ProofData {
        uint256 id;
        address owner;
        uint256 circuitId;
        bytes32 proofHash;
        uint256 createdAt;
        uint256 expiresAt;
        bool isRevoked;
    }
    
    /**
     * @dev Registers a new verifier circuit (admin only)
     * @param name The name of the circuit
     * @param description The description of the circuit
     * @param verifierContract The address of the verifier contract
     * @return The ID of the registered circuit
     */
    function registerCircuit(string calldata name, string calldata description, address verifierContract) external returns (uint256);
    
    /**
     * @dev Creates a new ZK proof
     * @param circuitId The ID of the circuit to use
     * @param proofData The raw proof data
     * @param publicInputs The public inputs for the proof
     * @param validityPeriod How long the proof should be valid for (in seconds)
     * @return The ID of the created proof
     */
    function createProof(
        uint256 circuitId, 
        bytes calldata proofData, 
        bytes calldata publicInputs,
        uint256 validityPeriod
    ) external returns (uint256);
    
    /**
     * @dev Verifies a ZK proof
     * @param proofId The ID of the proof to verify
     * @param verifierAddress The address of the verifier (if restricted)
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(uint256 proofId, address verifierAddress) external view returns (bool);
    
    /**
     * @dev Revokes a ZK proof
     * @param proofId The ID of the proof to revoke
     */
    function revokeProof(uint256 proofId) external;
    
    /**
     * @dev Gets information about a proof
     * @param proofId The ID of the proof
     * @return The proof data
     */
    function getProofData(uint256 proofId) external view returns (ProofData memory);
    
    /**
     * @dev Gets information about a circuit
     * @param circuitId The ID of the circuit
     * @return The circuit data
     */
    function getCircuitData(uint256 circuitId) external view returns (VerifierCircuit memory);
    
    /**
     * @dev Event emitted when a new circuit is registered
     */
    event CircuitRegistered(uint256 indexed circuitId, string name, address verifierContract);
    
    /**
     * @dev Event emitted when a new proof is created
     */
    event ProofCreated(uint256 indexed proofId, address indexed owner, uint256 indexed circuitId);
    
    /**
     * @dev Event emitted when a proof is revoked
     */
    event ProofRevoked(uint256 indexed proofId, address indexed revoker);
} 