// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISoulboundNFT
 * @dev Interface for the SoulboundNFT contract
 */
interface ISoulboundNFT {
    /**
     * @dev Mints a new certificate to a recipient
     * @param recipient The address that will receive the certificate
     * @param merkleProof The Merkle proof that verifies the recipient is eligible
     * @return The token ID of the minted certificate
     */
    function mintCertificate(address recipient, bytes32[] calldata merkleProof) external returns (uint256);
    
    /**
     * @dev Checks if an address is eligible to claim a certificate
     * @param recipient The address to check eligibility for
     * @param merkleProof The Merkle proof to verify eligibility
     * @return True if the address is eligible, false otherwise
     */
    function isEligible(address recipient, bytes32[] calldata merkleProof) external view returns (bool);
    
    /**
     * @dev Gets the certificate data for a token ID
     * @param tokenId The token ID to get data for
     * @return issuer The address of the certificate issuer
     * @return issuerLevel The level of the issuer (T1, T2, etc.)
     * @return metadataURI The URI for the certificate metadata
     * @return issuedTimestamp The timestamp when the certificate was issued
     */
    function getCertificateData(uint256 tokenId) external view returns (
        address issuer,
        uint8 issuerLevel,
        string memory metadataURI,
        uint256 issuedTimestamp
    );
    
    /**
     * @dev Event emitted when a certificate is minted
     */
    event CertificateMinted(address indexed recipient, uint256 indexed tokenId, address indexed issuer);
} 