const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IssuerRegistry", function () {
  let IssuerRegistry;
  let issuerRegistry;
  let owner;
  let issuer1;
  let issuer2;
  let admin;

  // Define tiers for clarity in tests
  const Tier = {
    NONE: 0,
    MANUAL: 1,
    T2: 2,
    T1: 3
  };

  beforeEach(async function () {
    // Get signers
    [owner, issuer1, issuer2, admin] = await ethers.getSigners();
    
    // Deploy IssuerRegistry
    IssuerRegistry = await ethers.getContractFactory("IssuerRegistry");
    issuerRegistry = await IssuerRegistry.deploy();
    await issuerRegistry.waitForDeployment();
    
    // Add admin
    await issuerRegistry.addAdmin(admin.address);
  });

  describe("Admin Management", function () {
    it("Should allow owner to add admins", async function () {
      // Owner adds an admin
      await issuerRegistry.addAdmin(issuer1.address);
      
      // Manually verify an issuer as the new admin to check if admin role works
      await issuerRegistry.connect(issuer1).manualVerifyIssuer(
        issuer2.address,
        "Test Organization"
      );
      
      // Check if the issuer was verified
      const tier = await issuerRegistry.getIssuerTier(issuer2.address);
      expect(tier).to.equal(Tier.MANUAL);
    });

    it("Should allow owner to remove admins", async function () {
      // Owner adds an admin
      await issuerRegistry.addAdmin(issuer1.address);
      
      // Owner removes the admin
      await issuerRegistry.removeAdmin(issuer1.address);
      
      // Try to manually verify an issuer as the removed admin - should fail
      await expect(
        issuerRegistry.connect(issuer1).manualVerifyIssuer(
          issuer2.address,
          "Test Organization"
        )
      ).to.be.revertedWith("IssuerRegistry: Caller is not an admin");
    });
  });

  describe("Issuer Verification", function () {
    it("Should verify an issuer with T1 verification", async function () {
      await issuerRegistry.connect(issuer1).verifyIssuerT1(
        "University of Blockchain",
        "blockchain.edu",
        "TXT Record: decentracert-verify=0x123456"
      );
      
      // Check if the issuer was verified
      const tier = await issuerRegistry.getIssuerTier(issuer1.address);
      expect(tier).to.equal(Tier.T1);
      
      // Check issuer data
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.name).to.equal("University of Blockchain");
      expect(issuerData.verificationData).to.equal("TXT Record: decentracert-verify=0x123456");
      expect(issuerData.isActive).to.be.true;
    });

    it("Should verify an issuer with T2 verification", async function () {
      await issuerRegistry.connect(issuer1).verifyIssuerT2(
        "Blockchain Bootcamp",
        "https://twitter.com/blockchainbootcamp/status/123456789"
      );
      
      // Check if the issuer was verified
      const tier = await issuerRegistry.getIssuerTier(issuer1.address);
      expect(tier).to.equal(Tier.T2);
      
      // Check issuer data
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.name).to.equal("Blockchain Bootcamp");
      expect(issuerData.verificationData).to.equal("https://twitter.com/blockchainbootcamp/status/123456789");
      expect(issuerData.isActive).to.be.true;
    });

    it("Should allow admin to manually verify an issuer", async function () {
      await issuerRegistry.connect(admin).manualVerifyIssuer(
        issuer1.address,
        "Rural Blockchain School"
      );
      
      // Check if the issuer was verified
      const tier = await issuerRegistry.getIssuerTier(issuer1.address);
      expect(tier).to.equal(Tier.MANUAL);
      
      // Check issuer data
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.name).to.equal("Rural Blockchain School");
      expect(issuerData.isActive).to.be.true;
    });

    it("Should prevent non-admins from manually verifying issuers", async function () {
      await expect(
        issuerRegistry.connect(issuer1).manualVerifyIssuer(
          issuer2.address,
          "Rural Blockchain School"
        )
      ).to.be.revertedWith("IssuerRegistry: Caller is not an admin");
    });
  });

  describe("Tier Upgrading", function () {
    it("Should allow T2 issuer to upgrade to T1", async function () {
      // First verify as T2
      await issuerRegistry.connect(issuer1).verifyIssuerT2(
        "Blockchain Bootcamp",
        "https://twitter.com/blockchainbootcamp/status/123456789"
      );
      
      // Check T2 verification
      let tier = await issuerRegistry.getIssuerTier(issuer1.address);
      expect(tier).to.equal(Tier.T2);
      
      // Now upgrade to T1
      await issuerRegistry.connect(issuer1).upgradeToT1(
        "blockchain.edu",
        "TXT Record: decentracert-verify=0x123456"
      );
      
      // Check T1 upgrade
      tier = await issuerRegistry.getIssuerTier(issuer1.address);
      expect(tier).to.equal(Tier.T1);
      
      // Check updated data
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.verificationData).to.equal("TXT Record: decentracert-verify=0x123456");
    });

    it("Should prevent non-T2 issuers from upgrading to T1", async function () {
      // Try to upgrade without being T2 first
      await expect(
        issuerRegistry.connect(issuer1).upgradeToT1(
          "blockchain.edu",
          "TXT Record: decentracert-verify=0x123456"
        )
      ).to.be.revertedWith("IssuerRegistry: Caller is not a T2 issuer");
    });
  });

  describe("Issuer Status Management", function () {
    it("Should allow admins to deactivate issuers", async function () {
      // First verify an issuer
      await issuerRegistry.connect(issuer1).verifyIssuerT1(
        "University of Blockchain",
        "blockchain.edu",
        "TXT Record: decentracert-verify=0x123456"
      );
      
      // Admin deactivates the issuer
      await issuerRegistry.connect(admin).deactivateIssuer(issuer1.address);
      
      // Check issuer status
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.isActive).to.be.false;
      
      // Check if isVerifiedIssuer returns false for inactive issuers
      const isVerified = await issuerRegistry.isVerifiedIssuer(issuer1.address);
      expect(isVerified).to.be.false;
    });

    it("Should allow admins to reactivate issuers", async function () {
      // First verify and deactivate an issuer
      await issuerRegistry.connect(issuer1).verifyIssuerT1(
        "University of Blockchain",
        "blockchain.edu",
        "TXT Record: decentracert-verify=0x123456"
      );
      await issuerRegistry.connect(admin).deactivateIssuer(issuer1.address);
      
      // Admin reactivates the issuer
      await issuerRegistry.connect(admin).reactivateIssuer(issuer1.address);
      
      // Check issuer status
      const issuerData = await issuerRegistry.getIssuerData(issuer1.address);
      expect(issuerData.isActive).to.be.true;
      
      // Check if isVerifiedIssuer returns true again
      const isVerified = await issuerRegistry.isVerifiedIssuer(issuer1.address);
      expect(isVerified).to.be.true;
    });
  });
}); 