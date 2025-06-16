// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ISoulboundNFT.sol";
import "./interfaces/IIssuerRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title SoulboundNFT
 * @dev Implementation of non-transferable (soulbound) NFTs for certificates
 */
contract SoulboundNFT is ERC721, Ownable, ISoulboundNFT {
    using Strings for uint256;
    
    // Token counter for NFT IDs
    uint256 private _tokenIdCounter;
    
    // Certificate data
    struct Certificate {
        address issuer;
        uint8 issuerLevel;
        string metadataURI;
        uint256 issuedAt;
        address recipient;
    }
    
    // Mapping from token ID to certificate data
    mapping(uint256 => Certificate) private _certificates;
    
    // Merkle root for whitelisting recipients
    bytes32 private _merkleRoot;
    
    // Address of the issuer registry contract
    address private _issuerRegistry;
    
    // Base URI for metadata
    string private _baseTokenURI;
    
    // Mapping from recipient to has-certificate flag to prevent duplicates
    mapping(address => bool) private _hasCertificate;
    
    // Error for soulbound transfers
    error SoulboundToken();
    
    event BaseURIUpdated(string oldBaseURI, string newBaseURI);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    
    /**
     * @dev Constructor for the SoulboundNFT contract
     * @param name Name of the NFT collection
     * @param symbol Symbol of the NFT collection
     * @param merkleRoot Merkle root for whitelisting recipients
     * @param issuerRegistry Address of the issuer registry contract
     * @param baseTokenURI Base URI for metadata
     */
    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleRoot,
        address issuerRegistry,
        string memory baseTokenURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _merkleRoot = merkleRoot;
        _issuerRegistry = issuerRegistry;
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Override _update to prevent transfers (except minting and burning)
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0)) and burning (to == address(0))
        // but prevent transfers (from != address(0) && to != address(0))
        if (from != address(0) && to != address(0)) {
            revert SoulboundToken();
        }
        
        return super._update(to, tokenId, auth);
    }
    
    /**
     * @dev Alias for mintCertificate to maintain compatibility with frontend
     * @param recipient The address that will receive the certificate
     * @param merkleProof The Merkle proof that verifies the recipient is eligible
     * @return The token ID of the minted certificate
     */
    function mint(address recipient, bytes32[] calldata merkleProof) external returns (uint256) {
        return mintCertificate(recipient, merkleProof);
    }
    
    /**
     * @dev Mints a new certificate to a recipient
     * @param recipient The address that will receive the certificate
     * @param merkleProof The Merkle proof that verifies the recipient is eligible
     * @return The token ID of the minted certificate
     */
    function mintCertificate(address recipient, bytes32[] calldata merkleProof) public override returns (uint256) {
        // Verify issuer is authorized
        require(
            IIssuerRegistry(_issuerRegistry).isVerifiedIssuer(msg.sender),
            "SoulboundNFT: Caller is not a verified issuer"
        );
        
        // Verify recipient is in the whitelist
        require(
            isEligible(recipient, merkleProof),
            "SoulboundNFT: Recipient is not eligible"
        );
        
        // Verify recipient does not already possess a certificate
        require(!_hasCertificate[recipient], "SoulboundNFT: Recipient already possesses a certificate");
        
        // Get issuer level
        IIssuerRegistry.IssuerTier issuerTier = IIssuerRegistry(_issuerRegistry).getIssuerTier(msg.sender);
        
        // Increment token ID
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        // Mint NFT
        _mint(recipient, tokenId);
        
        // Store certificate data
        _certificates[tokenId] = Certificate({
            issuer: msg.sender,
            issuerLevel: uint8(issuerTier),
            metadataURI: string(abi.encodePacked(_baseTokenURI, tokenId.toString())),
            issuedAt: block.timestamp,
            recipient: recipient
        });
        
        // Mark recipient as having a cert
        _hasCertificate[recipient] = true;
        
        emit CertificateMinted(recipient, tokenId, msg.sender);
        
        return tokenId;
    }
    
    /**
     * @dev Checks if an address is eligible to claim a certificate
     * @param recipient The address to check eligibility for
     * @param merkleProof The Merkle proof to verify eligibility
     * @return True if the address is eligible, false otherwise
     */
    function isEligible(address recipient, bytes32[] calldata merkleProof) public view override returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return MerkleProof.verify(merkleProof, _merkleRoot, leaf);
    }
    
    /**
     * @dev Gets the certificate data for a token ID
     * @param tokenId The token ID to get data for
     * @return issuer The address of the certificate issuer
     * @return issuerLevel The level of the issuer (T1, T2, etc.)
     * @return metadataURI The URI for the certificate metadata
     * @return issuedTimestamp The timestamp when the certificate was issued
     */
    function getCertificateData(uint256 tokenId) external view override returns (
        address issuer,
        uint8 issuerLevel,
        string memory metadataURI,
        uint256 issuedTimestamp
    ) {
        require(_exists(tokenId), "SoulboundNFT: Query for nonexistent token");
        
        Certificate memory cert = _certificates[tokenId];
        
        return (
            cert.issuer,
            cert.issuerLevel,
            cert.metadataURI,
            cert.issuedAt
        );
    }
    
    /**
     * @dev Gets the issuer of a token
     * @param tokenId The token ID
     * @return The address of the issuer
     */
    function issuerOf(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "SoulboundNFT: Query for nonexistent token");
        return _certificates[tokenId].issuer;
    }
    
    /**
     * @dev Gets the issuance timestamp of a token
     * @param tokenId The token ID
     * @return The timestamp when the token was issued
     */
    function getIssuedAt(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "SoulboundNFT: Query for nonexistent token");
        return _certificates[tokenId].issuedAt;
    }
    
    /**
     * @dev Gets the URI for a token's metadata
     * @param tokenId The token ID to get the URI for
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "SoulboundNFT: URI query for nonexistent token");
        return _certificates[tokenId].metadataURI;
    }
    
    /**
     * @dev Updates the base token URI
     * @param newBaseURI The new base token URI
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        string memory old = _baseTokenURI;
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(old, newBaseURI);
    }
    
    /**
     * @dev Updates the Merkle root
     * @param newMerkleRoot The new Merkle root
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        bytes32 old = _merkleRoot;
        _merkleRoot = newMerkleRoot;
        emit MerkleRootUpdated(old, newMerkleRoot);
    }
    
    /**
     * @dev Gets the current Merkle root
     * @return The current Merkle root
     */
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }
    
    /**
     * @dev Utility function to check if a token exists
     * @param tokenId The token ID to check
     * @return True if the token exists, false otherwise
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId != 0 && tokenId <= _tokenIdCounter && _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @dev Overrides approve to block approvals for soul-bound tokens.
     */
    function approve(address, uint256) public pure override {
        revert SoulboundToken();
    }

    /**
     * @dev Overrides setApprovalForAll to block operator approvals.
     */
    function setApprovalForAll(address, bool) public pure override {
        revert SoulboundToken();
    }

    /**
     * @dev Overrides getApproved to always return zero address.
     */
    function getApproved(uint256) public pure override returns (address) {
        return address(0);
    }

    /**
     * @dev Burns a certificate. Callable by the token owner or contract owner.
     * Clearing the recipient flag enables re-issuing if needed.
     */
    function burn(uint256 tokenId) external {
        address tokenOwner = _ownerOf(tokenId);
        require(
            msg.sender == tokenOwner || msg.sender == owner(),
            "SoulboundNFT: Not authorised to burn"
        );
        _burn(tokenId);
        _hasCertificate[tokenOwner] = false;
    }
} 