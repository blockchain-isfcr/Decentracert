// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIssuerRegistry
 * @dev Interface for the IssuerRegistry contract that manages verification of certificate issuers
 */
interface IIssuerRegistry {
    /**
     * @dev Enum representing the verification tier level of an issuer
     * T1: Highest level, verified via DNS
     * T2: Medium level, verified via social media
     * MANUAL: Lowest level, verified manually by admin
     * NONE: Not verified
     */
    enum IssuerTier { NONE, MANUAL, T2, T1 }
    
    /**
     * @dev Struct containing issuer verification data
     */
    struct IssuerData {
        address issuerAddress;
        IssuerTier tier;
        string name;
        string verificationData; // Domain name for T1, social media URL for T2
        uint256 verifiedAt;
        bool isActive;
    }
    
    /**
     * @dev Verifies an issuer with T1 verification (DNS)
     * @param issuerName The name of the issuer organization
     * @param domain The domain name used for verification
     * @param verificationData Additional data used in verification process
     */
    function verifyIssuerT1(string calldata issuerName, string calldata domain, string calldata verificationData) external;
    
    /**
     * @dev Verifies an issuer with T2 verification (social media)
     * @param issuerName The name of the issuer organization
     * @param socialMediaUrl The URL of the social media post used for verification
     */
    function verifyIssuerT2(string calldata issuerName, string calldata socialMediaUrl) external;
    
    /**
     * @dev Manually verifies an issuer (only admin)
     * @param issuerAddress The address to be verified
     * @param issuerName The name of the issuer organization
     */
    function manualVerifyIssuer(address issuerAddress, string calldata issuerName) external;
    
    /**
     * @dev Upgrades an issuer from T2 to T1
     * @param domain The domain name used for verification
     * @param verificationData Additional data used in verification process
     */
    function upgradeToT1(string calldata domain, string calldata verificationData) external;
    
    /**
     * @dev Checks if an address is a verified issuer
     * @param issuer The address to check
     * @return True if the address is a verified issuer, false otherwise
     */
    function isVerifiedIssuer(address issuer) external view returns (bool);
    
    /**
     * @dev Gets the tier level of an issuer
     * @param issuer The address to check
     * @return The tier level of the issuer
     */
    function getIssuerTier(address issuer) external view returns (IssuerTier);
    
    /**
     * @dev Gets the data for an issuer
     * @param issuer The address to get data for
     * @return The issuer data
     */
    function getIssuerData(address issuer) external view returns (IssuerData memory);
    
    /**
     * @dev Event emitted when an issuer is verified
     */
    event IssuerVerified(address indexed issuer, IssuerTier tier, string name);
    
    /**
     * @dev Event emitted when an issuer is upgraded
     */
    event IssuerUpgraded(address indexed issuer, IssuerTier fromTier, IssuerTier toTier);
} 