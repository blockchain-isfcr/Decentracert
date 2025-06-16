// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IIssuerRegistry.sol";

/**
 * @title IssuerRegistry
 * @dev Implementation of the issuer registry for verifying certificate issuers
 */
contract IssuerRegistry is IIssuerRegistry, Ownable {
    // Mapping from issuer address to issuer data
    mapping(address => IssuerData) private _issuers;
    
    // Mapping from hashed domain (keccak256(lowercase)) to issuer address
    mapping(bytes32 => address) private _domainToIssuer;
    
    // Mapping from hashed social media URL to issuer address
    mapping(bytes32 => address) private _socialMediaToIssuer;
    
    // Admin addresses for manual verification
    mapping(address => bool) private _admins;
    
    /**
     * @dev Emitted when an admin is added.
     */
    event AdminAdded(address indexed admin);

    /**
     * @dev Emitted when an admin is removed.
     */
    event AdminRemoved(address indexed admin);

    /**
     * @dev Emitted when an issuer is deactivated or reactivated.
     */
    event IssuerStatusChanged(address indexed issuer, bool isActive);

    /**
     * @dev Helper to compute a case-insensitive hash of a string.
     */
    function _hash(string memory input) private pure returns (bytes32) {
        return keccak256(bytes(_toLower(input)));
    }

    /**
     * @dev Converts ASCII string to lower-case (English letters only).
     */
    function _toLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if (bStr[i] >= 0x41 && bStr[i] <= 0x5A) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    /**
     * @dev Constructor for IssuerRegistry
     */
    constructor() Ownable(msg.sender) {
        // Add deployer as admin
        _admins[msg.sender] = true;
    }
    
    /**
     * @dev Modifier to restrict function access to admins
     */
    modifier onlyAdmin() {
        require(_admins[msg.sender], "IssuerRegistry: Caller is not an admin");
        _;
    }
    
    /**
     * @dev Add an admin
     * @param admin The address to add as admin
     */
    function addAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
        emit AdminAdded(admin);
    }
    
    /**
     * @dev Remove an admin
     * @param admin The address to remove as admin
     */
    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }
    
    /**
     * @dev Check if an address is admin.
     */
    function isAdmin(address addr) external view returns (bool) {
        return _admins[addr];
    }
    
    /**
     * @dev Verifies an issuer with T1 verification (DNS)
     * @param issuerName The name of the issuer organization
     * @param domain The domain name used for verification
     * @param verificationData Additional data used in verification process
     */
    function verifyIssuerT1(
        string calldata issuerName,
        string calldata domain,
        string calldata verificationData
    ) external override {
        // In a real implementation, this would involve checking DNS TXT records
        // For this demo, we'll simulate the verification
        
        bytes32 domainHash = _hash(domain);
        // Ensure domain isn't already registered
        require(_domainToIssuer[domainHash] == address(0), "IssuerRegistry: Domain already registered");
        
        // Create issuer data
        _issuers[msg.sender] = IssuerData({
            issuerAddress: msg.sender,
            tier: IssuerTier.T1,
            name: issuerName,
            verificationData: verificationData,
            verifiedAt: block.timestamp,
            isActive: true
        });
        
        // Register domain
        _domainToIssuer[domainHash] = msg.sender;
        
        emit IssuerVerified(msg.sender, IssuerTier.T1, issuerName);
    }
    
    /**
     * @dev Verifies an issuer with T2 verification (social media)
     * @param issuerName The name of the issuer organization
     * @param socialMediaUrl The URL of the social media post used for verification
     */
    function verifyIssuerT2(
        string calldata issuerName,
        string calldata socialMediaUrl
    ) external override {
        // In a real implementation, this would involve checking the social media post
        // For this demo, we'll simulate the verification
        
        bytes32 urlHash = _hash(socialMediaUrl);
        require(_socialMediaToIssuer[urlHash] == address(0), "IssuerRegistry: Social media URL already registered");
        
        // Create issuer data
        _issuers[msg.sender] = IssuerData({
            issuerAddress: msg.sender,
            tier: IssuerTier.T2,
            name: issuerName,
            verificationData: socialMediaUrl,
            verifiedAt: block.timestamp,
            isActive: true
        });
        
        // Register social media URL
        _socialMediaToIssuer[urlHash] = msg.sender;
        
        emit IssuerVerified(msg.sender, IssuerTier.T2, issuerName);
    }
    
    /**
     * @dev Manually verifies an issuer (only admin)
     * @param issuerAddress The address to be verified
     * @param issuerName The name of the issuer organization
     */
    function manualVerifyIssuer(
        address issuerAddress,
        string calldata issuerName
    ) external override onlyAdmin {
        // Create issuer data
        _issuers[issuerAddress] = IssuerData({
            issuerAddress: issuerAddress,
            tier: IssuerTier.MANUAL,
            name: issuerName,
            verificationData: "Manual verification",
            verifiedAt: block.timestamp,
            isActive: true
        });
        
        emit IssuerVerified(issuerAddress, IssuerTier.MANUAL, issuerName);
    }
    
    /**
     * @dev Upgrades an issuer from T2 to T1
     * @param domain The domain name used for verification
     * @param verificationData Additional data used in verification process
     */
    function upgradeToT1(
        string calldata domain,
        string calldata verificationData
    ) external override {
        // Ensure caller is a T2 issuer
        require(_issuers[msg.sender].tier == IssuerTier.T2, "IssuerRegistry: Caller is not a T2 issuer");
        
        bytes32 domainHash = _hash(domain);
        // Ensure domain isn't already registered
        require(_domainToIssuer[domainHash] == address(0), "IssuerRegistry: Domain already registered");
        
        // Store old data for event
        IssuerTier oldTier = _issuers[msg.sender].tier;
        string memory oldVerificationData = _issuers[msg.sender].verificationData;
        
        // Update issuer data
        _issuers[msg.sender].tier = IssuerTier.T1;
        _issuers[msg.sender].verificationData = verificationData;
        _issuers[msg.sender].verifiedAt = block.timestamp;
        
        // Register domain
        _domainToIssuer[domainHash] = msg.sender;
        
        // Unregister social media URL
        bytes32 oldHash = _hash(oldVerificationData);
        _socialMediaToIssuer[oldHash] = address(0);
        
        emit IssuerUpgraded(msg.sender, oldTier, IssuerTier.T1);
    }
    
    /**
     * @dev Checks if an address is a verified issuer
     * @param issuer The address to check
     * @return True if the address is a verified issuer, false otherwise
     */
    function isVerifiedIssuer(address issuer) external view override returns (bool) {
        return _issuers[issuer].tier != IssuerTier.NONE && _issuers[issuer].isActive;
    }
    
    /**
     * @dev Gets the tier level of an issuer
     * @param issuer The address to check
     * @return The tier level of the issuer
     */
    function getIssuerTier(address issuer) external view override returns (IssuerTier) {
        return _issuers[issuer].tier;
    }
    
    /**
     * @dev Gets the data for an issuer
     * @param issuer The address to get data for
     * @return The issuer data
     */
    function getIssuerData(address issuer) external view override returns (IssuerData memory) {
        return _issuers[issuer];
    }
    
    /**
     * @dev Checks if a domain is registered
     * @param domain The domain to check
     * @return The address associated with the domain, or address(0) if not registered
     */
    function getDomainIssuer(string calldata domain) external view returns (address) {
        return _domainToIssuer[_hash(domain)];
    }
    
    /**
     * @dev Checks if a social media URL is registered
     * @param socialMediaUrl The social media URL to check
     * @return The address associated with the social media URL, or address(0) if not registered
     */
    function getSocialMediaIssuer(string calldata socialMediaUrl) external view returns (address) {
        return _socialMediaToIssuer[_hash(socialMediaUrl)];
    }
    
    /**
     * @dev Deactivates an issuer
     * @param issuer The address to deactivate
     */
    function deactivateIssuer(address issuer) external onlyAdmin {
        require(_issuers[issuer].tier != IssuerTier.NONE, "IssuerRegistry: Not a registered issuer");
        _issuers[issuer].isActive = false;
        emit IssuerStatusChanged(issuer, false);
    }
    
    /**
     * @dev Reactivates an issuer
     * @param issuer The address to reactivate
     */
    function reactivateIssuer(address issuer) external onlyAdmin {
        require(_issuers[issuer].tier != IssuerTier.NONE, "IssuerRegistry: Not a registered issuer");
        _issuers[issuer].isActive = true;
        emit IssuerStatusChanged(issuer, true);
    }
} 