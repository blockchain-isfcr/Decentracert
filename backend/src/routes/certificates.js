const express = require('express');
const keccak256 = require('keccak256');
const { MerkleTree } = require('merkletreejs');
const { ethers } = require('ethers');
const { getContracts } = require('../services/contracts');
const path = require('path');

const router = express.Router();

// In-memory store (replace with DB in production)
const collections = new Map(); // key: merkleRoot => { tree, addresses }

/**
 * Generate Merkle Tree & store
 * POST /api/certificate/prepare
 * body: { addresses: string[], baseTokenURI }
 */
router.post('/prepare', async (req, res) => {
  const { addresses, baseTokenURI } = req.body;
  if (!Array.isArray(addresses) || addresses.length === 0) {
    return res.status(400).json({ error: 'addresses array required' });
  }

  try {
    // Validate addresses
    const checksummed = addresses.map((addr) => ethers.getAddress(addr));

    const leaves = checksummed.map((addr) => keccak256(addr));
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const merkleRoot = tree.getHexRoot().toLowerCase();

    collections.set(merkleRoot, { tree, addresses: checksummed, baseTokenURI });

    return res.json({ merkleRoot, count: checksummed.length });
  } catch (err) {
    console.error('prepare error:', err);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * Deploy SoulboundNFT contract referencing specified merkleRoot
 * POST /api/certificate/deploy
 * body: { name, symbol, merkleRoot, baseTokenURI }
 */
router.post('/deploy', async (req, res) => {
  const { name, symbol, merkleRoot, baseTokenURI } = req.body;
  if (!name || !symbol || !merkleRoot) return res.status(400).json({ error: 'name, symbol, merkleRoot required' });

  try {
    const { issuerRegistry, signer } = await getContracts();
    // Deploy SoulboundNFT using factory pattern or via Hardhat deployment script.
    // For simplicity we use ethers ContractFactory. Load compiled artifact from contracts project
    const artifactPath = path.join(__dirname, '../../../contracts/artifacts/contracts/SoulboundNFT.sol/SoulboundNFT.json');
    const artifact = require(artifactPath);
    const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, signer);

    const contract = await factory.deploy(name, symbol, merkleRoot, issuerRegistry.target, baseTokenURI || '');
    await contract.waitForDeployment();

    const address = await contract.getAddress();

    return res.json({ deployedAt: address });
  } catch (err) {
    console.error('deploy error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

/**
 * Returns Merkle Proof for recipient within a collection root
 * GET /api/certificate/proof/:merkleRoot/:address
 */
router.get('/proof/:merkleRoot/:address', (req, res) => {
  const { merkleRoot, address } = req.params;
  const entry = collections.get(merkleRoot.toLowerCase());
  if (!entry) return res.status(404).json({ error: 'Merkle root not found' });

  try {
    const leaf = keccak256(ethers.getAddress(address));
    const proof = entry.tree.getHexProof(leaf);
    return res.json({ proof, length: proof.length });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router; 