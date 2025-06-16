const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Load deployment addresses
function loadDeployment(networkName) {
  const deploymentsPath = path.join(__dirname, '../../../contracts/deployments', `${networkName}.json`);
  if (!fs.existsSync(deploymentsPath)) {
    throw new Error(`Deployment file not found for ${networkName}`);
  }
  return JSON.parse(fs.readFileSync(deploymentsPath, 'utf8'));
}

// Load ABI JSON helpers
function loadABI(contract) {
  const abiPath = path.join(__dirname, '../../../frontend/src/services/abis', `${contract}.json`);
  if (!fs.existsSync(abiPath)) {
    throw new Error(`ABI file missing for ${contract}`);
  }
  return require(abiPath).abi; // the json includes .abi property per Hardhat artifact
}

let cached;

async function getContracts() {
  if (cached) return cached;

  const network = process.env.NETWORK || 'sepolia';
  const deployment = loadDeployment(network);

  const providerUrl = process.env.RPC_URL || `https://${network}.infura.io/v3/${process.env.INFURA_API_KEY}`;
  const provider = new ethers.JsonRpcProvider(providerUrl);

  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) throw new Error('PRIVATE_KEY missing in env');

  const signer = new ethers.Wallet(privateKey, provider);

  const issuerRegistry = new ethers.Contract(deployment.issuerRegistry, loadABI('IssuerRegistry'), signer);
  const soulboundNFT = new ethers.Contract(deployment.soulboundNFT, loadABI('SoulboundNFT'), signer);
  const zkVerifier = new ethers.Contract(deployment.zkVerifier, loadABI('ZKVerifier'), signer);

  cached = { provider, signer, issuerRegistry, soulboundNFT, zkVerifier };
  return cached;
}

module.exports = { getContracts }; 