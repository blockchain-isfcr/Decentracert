// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IZKVerifier.sol";

/**
 * @title ZKVerifier
 * @dev Contract for managing zero-knowledge proof verification for certificates
 */
contract ZKVerifier is IZKVerifier, Ownable {
    // Counter for circuit IDs
    uint256 private _circuitIdCounter;
    
    // Counter for proof IDs
    uint256 private _proofIdCounter;
    
    // Mapping from circuit ID to circuit data
    mapping(uint256 => VerifierCircuit) private _circuits;
    
    // Mapping from proof ID to proof data
    mapping(uint256 => ProofData) private _proofs;
    
    // Mapping from owner to proof IDs
    mapping(address => uint256[]) private _ownerProofs;
    
    // Admin addresses
    mapping(address => bool) private _admins;
    
    /**
     * @dev Constructor for ZKVerifier
     */
    constructor() Ownable(msg.sender) {
        // Add deployer as admin
        _admins[msg.sender] = true;
    }
    
    /**
     * @dev Modifier to restrict function access to admins
     */
    modifier onlyAdmin() {
        require(_admins[msg.sender], "ZKVerifier: Caller is not an admin");
        _;
    }
    
    /**
     * @dev Add an admin
     * @param admin The address to add as admin
     */
    function addAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
    }
    
    /**
     * @dev Remove an admin
     * @param admin The address to remove as admin
     */
    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
    }
    
    /**
     * @dev Registers a new verifier circuit (admin only)
     * @param name The name of the circuit
     * @param description The description of the circuit
     * @param verifierContract The address of the verifier contract
     * @return The ID of the registered circuit
     */
    function registerCircuit(
        string calldata name,
        string calldata description,
        address verifierContract
    ) external override onlyAdmin returns (uint256) {
        require(verifierContract != address(0), "ZKVerifier: Invalid verifier contract address");
        
        // Increment circuit ID
        _circuitIdCounter++;
        uint256 circuitId = _circuitIdCounter;
        
        // Store circuit data
        _circuits[circuitId] = VerifierCircuit({
            id: circuitId,
            name: name,
            description: description,
            verifierContract: verifierContract,
            isActive: true
        });
        
        emit CircuitRegistered(circuitId, name, verifierContract);
        
        return circuitId;
    }
    
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
    ) external override returns (uint256) {
        require(_circuits[circuitId].isActive, "ZKVerifier: Circuit is not active");
        
        // In a real implementation, we would actually verify the proof
        // using the circuit's verifier contract
        // For this demo, we'll assume the proof is valid
        
        // Increment proof ID
        _proofIdCounter++;
        uint256 proofId = _proofIdCounter;
        
        // Calculate proof hash
        bytes32 proofHash = keccak256(abi.encodePacked(proofData, publicInputs));
        
        // Calculate expiration time
        uint256 expiresAt = block.timestamp + validityPeriod;
        
        // Store proof data
        _proofs[proofId] = ProofData({
            id: proofId,
            owner: msg.sender,
            circuitId: circuitId,
            proofHash: proofHash,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            isRevoked: false
        });
        
        // Add proof to owner's list
        _ownerProofs[msg.sender].push(proofId);
        
        emit ProofCreated(proofId, msg.sender, circuitId);
        
        return proofId;
    }
    
    /**
     * @dev Convenience wrapper that skips the optional verifierAddress ACL.
     */
    function verifyProof(uint256 proofId) external view returns (bool) {
        return _isProofValid(proofId);
    }
    
    /**
     * @dev Internal validation logic shared by both verify functions.
     */
    function _isProofValid(uint256 proofId) internal view returns (bool) {
        ProofData memory proof = _proofs[proofId];
        if (proof.id == 0) return false;
        if (proof.isRevoked) return false;
        if (block.timestamp > proof.expiresAt) return false;
        return true;
    }
    
    /**
     * @dev Verifies a ZK proof
     * @param proofId The ID of the proof to verify
     * @param verifierAddress The address of the verifier (if restricted)
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(uint256 proofId, address verifierAddress) external view override returns (bool) {
        ProofData memory proof = _proofs[proofId];
        
        // Check if proof exists
        if (proof.id == 0) {
            return false;
        }
        
        // Check if proof is revoked
        if (proof.isRevoked) {
            return false;
        }
        
        // Check if proof is expired
        if (block.timestamp > proof.expiresAt) {
            return false;
        }
        
        // Optional ACL enforcement if verifierAddress specified
        if (verifierAddress != address(0) && !_admins[verifierAddress]) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @dev Revokes a ZK proof
     * @param proofId The ID of the proof to revoke
     */
    function revokeProof(uint256 proofId) external override {
        ProofData storage proof = _proofs[proofId];
        
        // Check if proof exists
        require(proof.id != 0, "ZKVerifier: Proof does not exist");
        
        // Check if caller is the owner or an admin
        require(
            proof.owner == msg.sender || _admins[msg.sender],
            "ZKVerifier: Caller is not authorized to revoke this proof"
        );
        
        // Revoke the proof
        proof.isRevoked = true;
        
        emit ProofRevoked(proofId, msg.sender);
    }
    
    /**
     * @dev Gets information about a proof
     * @param proofId The ID of the proof
     * @return The proof data
     */
    function getProofData(uint256 proofId) external view override returns (ProofData memory) {
        return _proofs[proofId];
    }
    
    /**
     * @dev Gets information about a proof (alias for frontend compatibility)
     * @param proofId The ID of the proof
     * @return The proof data
     */
    function getProof(uint256 proofId) external view returns (ProofData memory) {
        return _proofs[proofId];
    }
    
    /**
     * @dev Gets information about a circuit
     * @param circuitId The ID of the circuit
     * @return The circuit data
     */
    function getCircuitData(uint256 circuitId) external view override returns (VerifierCircuit memory) {
        return _circuits[circuitId];
    }
    
    /**
     * @dev Gets all proofs owned by an address
     * @param owner The address to get proofs for
     * @return An array of proof IDs
     */
    function getProofsByOwner(address owner) external view returns (uint256[] memory) {
        return _ownerProofs[owner];
    }
    
    /**
     * @dev Gets the number of proofs created by a user
     * @param user The address of the user
     * @return The number of proofs
     */
    function getProofCount(address user) external view returns (uint256) {
        return _ownerProofs[user].length;
    }
    
    /**
     * @dev Gets a proof ID by index in a user's proofs
     * @param user The address of the user
     * @param index The index in the user's proof array
     * @return The proof ID
     */
    function userProofByIndex(address user, uint256 index) external view returns (uint256) {
        require(index < _ownerProofs[user].length, "ZKVerifier: Index out of bounds");
        return _ownerProofs[user][index];
    }
    
    /**
     * @dev Deactivate a circuit
     * @param circuitId The ID of the circuit to deactivate
     */
    function deactivateCircuit(uint256 circuitId) external onlyAdmin {
        require(_circuits[circuitId].id != 0, "ZKVerifier: Circuit does not exist");
        _circuits[circuitId].isActive = false;
    }
    
    /**
     * @dev Reactivate a circuit
     * @param circuitId The ID of the circuit to reactivate
     */
    function reactivateCircuit(uint256 circuitId) external onlyAdmin {
        require(_circuits[circuitId].id != 0, "ZKVerifier: Circuit does not exist");
        _circuits[circuitId].isActive = true;
    }
} 