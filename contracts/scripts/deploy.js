// We require the Hardhat Runtime Environment explicitly here.
const hre = require("hardhat");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Deploying contracts with the account:", (await ethers.getSigners())[0].address);

  // Deploy IssuerRegistry
  const IssuerRegistry = await ethers.getContractFactory("IssuerRegistry");
  const issuerRegistry = await IssuerRegistry.deploy();
  await issuerRegistry.waitForDeployment();
  const issuerRegistryAddress = await issuerRegistry.getAddress();
  console.log("IssuerRegistry deployed to:", issuerRegistryAddress);

  // Create a Merkle root (for demo purposes, this is just a dummy value)
  // In production, you would generate this from your whitelist
  const merkleRoot = "0x" + "0".repeat(64);

  // Deploy SoulboundNFT
  const SoulboundNFT = await ethers.getContractFactory("SoulboundNFT");
  const soulboundNFT = await SoulboundNFT.deploy(
    "Certificate NFT",
    "CERT",
    merkleRoot,
    issuerRegistryAddress,
    "https://example.com/metadata/"
  );
  await soulboundNFT.waitForDeployment();
  const soulboundNFTAddress = await soulboundNFT.getAddress();
  console.log("SoulboundNFT deployed to:", soulboundNFTAddress);

  // Deploy ZKVerifier
  const ZKVerifier = await ethers.getContractFactory("ZKVerifier");
  const zkVerifier = await ZKVerifier.deploy();
  await zkVerifier.waitForDeployment();
  const zkVerifierAddress = await zkVerifier.getAddress();
  console.log("ZKVerifier deployed to:", zkVerifierAddress);

  // Write contract addresses to a file
  const deploymentInfo = {
    network: hre.network.name,
    issuerRegistry: issuerRegistryAddress,
    soulboundNFT: soulboundNFTAddress,
    zkVerifier: zkVerifierAddress,
    timestamp: new Date().toISOString()
  };

  // Create the deployment info directory if it doesn't exist
  const deploymentDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentDir)) {
    fs.mkdirSync(deploymentDir);
  }

  // Write the deployment info to a file
  fs.writeFileSync(
    path.join(deploymentDir, `${hre.network.name}.json`),
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log(`Deployment information written to deployments/${hre.network.name}.json`);

  // Instructions for the next steps
  console.log("\nNext steps:");
  console.log("1. Update the CONTRACT_ADDRESSES in frontend/src/services/ContractService.js with the above addresses");
  console.log("2. Update the contract addresses in frontend/deploy.js if you plan to use it");
  console.log("3. Run 'cd frontend && npm run build' to build the frontend with the new contract addresses");
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 