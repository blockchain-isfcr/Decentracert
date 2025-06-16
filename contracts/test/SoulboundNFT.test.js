const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe("SoulboundNFT", function () {
  let IssuerRegistry;
  let issuerRegistry;
  let SoulboundNFT;
  let soulboundNFT;
  let owner;
  let issuer;
  let recipient1;
  let recipient2;
  let nonWhitelisted;
  let merkleTree;
  let merkleRoot;
  let proof1;
  let proof2;
  
  // Helper function to create a leaf from an address
  function createLeaf(address) {
    return Buffer.from(
      ethers.solidityPackedKeccak256(['address'], [address]).slice(2),
      'hex'
    );
  }

  beforeEach(async function () {
    // Get signers
    [owner, issuer, recipient1, recipient2, nonWhitelisted] = await ethers.getSigners();
    
    // Create Merkle tree with recipient1 and recipient2
    const leaves = [recipient1.address, recipient2.address].map(addr => createLeaf(addr));
    merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    merkleRoot = merkleTree.getHexRoot();
    
    // Get proofs for recipients
    proof1 = merkleTree.getHexProof(createLeaf(recipient1.address));
    proof2 = merkleTree.getHexProof(createLeaf(recipient2.address));
    
    // Deploy IssuerRegistry
    IssuerRegistry = await ethers.getContractFactory("IssuerRegistry");
    issuerRegistry = await IssuerRegistry.deploy();
    await issuerRegistry.waitForDeployment();
    
    // Verify issuer as T1
    await issuerRegistry.connect(owner).manualVerifyIssuer(
      issuer.address,
      "Test Issuer Organization"
    );
    
    // Deploy SoulboundNFT
    SoulboundNFT = await ethers.getContractFactory("SoulboundNFT");
    soulboundNFT = await SoulboundNFT.deploy(
      "Test Certificate",
      "TCERT",
      merkleRoot,
      await issuerRegistry.getAddress(),
      "ipfs://test/"
    );
    await soulboundNFT.waitForDeployment();
  });

  describe("Certificate Minting", function () {
    it("Should allow verified issuer to mint certificates to whitelisted recipients", async function () {
      // Mint certificate
      await soulboundNFT.connect(issuer).mintCertificate(recipient1.address, proof1);
      
      // Check certificate ownership
      const tokenId = 1; // First token ID
      const owner = await soulboundNFT.ownerOf(tokenId);
      expect(owner).to.equal(recipient1.address);
      
      // Check certificate data
      const certData = await soulboundNFT.getCertificateData(tokenId);
      expect(certData[0]).to.equal(issuer.address); // issuer
      expect(certData[1]).to.equal(1); // issuerLevel (MANUAL)
      expect(certData[2]).to.equal("ipfs://test/1"); // metadataURI
    });

    it("Should prevent non-verified issuers from minting certificates", async function () {
      // Try to mint as non-verified issuer
      await expect(
        soulboundNFT.connect(nonWhitelisted).mintCertificate(recipient1.address, proof1)
      ).to.be.revertedWith("SoulboundNFT: Caller is not a verified issuer");
    });

    it("Should prevent minting to non-whitelisted recipients", async function () {
      // Try to mint to non-whitelisted recipient
      await expect(
        soulboundNFT.connect(issuer).mintCertificate(nonWhitelisted.address, [])
      ).to.be.revertedWith("SoulboundNFT: Recipient is not eligible");
    });

    it("Should prevent minting with invalid Merkle proof", async function () {
      // Try to mint with wrong proof (using proof1 for recipient2)
      await expect(
        soulboundNFT.connect(issuer).mintCertificate(recipient2.address, proof1)
      ).to.be.revertedWith("SoulboundNFT: Recipient is not eligible");
    });
  });

  describe("Soulbound Properties", function () {
    it("Should prevent transferring NFTs", async function () {
      // First mint a certificate
      await soulboundNFT.connect(issuer).mintCertificate(recipient1.address, proof1);
      
      // Try to transfer it
      const tokenId = 1;
      await expect(
        soulboundNFT.connect(recipient1).transferFrom(recipient1.address, recipient2.address, tokenId)
      ).to.be.revertedWithCustomError(soulboundNFT, "SoulboundToken");
    });
  });

  describe("Merkle Root Management", function () {
    it("Should allow owner to update Merkle root", async function () {
      // Create new Merkle tree with different recipients
      const newLeaves = [nonWhitelisted.address].map(addr => createLeaf(addr));
      const newMerkleTree = new MerkleTree(newLeaves, keccak256, { sortPairs: true });
      const newMerkleRoot = newMerkleTree.getHexRoot();
      
      // Update Merkle root
      await soulboundNFT.connect(owner).setMerkleRoot(newMerkleRoot);
      
      // Verify new root is set
      const root = await soulboundNFT.getMerkleRoot();
      expect(root).to.equal(newMerkleRoot);
      
      // Get proof for previously non-whitelisted address
      const newProof = newMerkleTree.getHexProof(createLeaf(nonWhitelisted.address));
      
      // Should be able to mint to previously non-whitelisted address
      await soulboundNFT.connect(issuer).mintCertificate(nonWhitelisted.address, newProof);
      
      // Previous recipients should no longer be eligible
      await expect(
        soulboundNFT.connect(issuer).mintCertificate(recipient1.address, proof1)
      ).to.be.revertedWith("SoulboundNFT: Recipient is not eligible");
    });

    it("Should prevent non-owners from updating Merkle root", async function () {
      const newMerkleRoot = "0x1234567890123456789012345678901234567890123456789012345678901234";
      
      // Try to update Merkle root as non-owner
      await expect(
        soulboundNFT.connect(issuer).setMerkleRoot(newMerkleRoot)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("URI Management", function () {
    it("Should return correct token URI", async function () {
      // Mint certificate
      await soulboundNFT.connect(issuer).mintCertificate(recipient1.address, proof1);
      
      // Check token URI
      const tokenId = 1;
      const uri = await soulboundNFT.tokenURI(tokenId);
      expect(uri).to.equal("ipfs://test/1");
    });

    it("Should allow owner to update base URI", async function () {
      // Mint certificate
      await soulboundNFT.connect(issuer).mintCertificate(recipient1.address, proof1);
      
      // Update base URI
      await soulboundNFT.connect(owner).setBaseURI("https://example.com/");
      
      // Check updated token URI
      const tokenId = 1;
      const uri = await soulboundNFT.tokenURI(tokenId);
      expect(uri).to.equal("https://example.com/1");
    });

    it("Should prevent non-owners from updating base URI", async function () {
      // Try to update base URI as non-owner
      await expect(
        soulboundNFT.connect(issuer).setBaseURI("https://example.com/")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
}); 