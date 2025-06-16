const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { ethers } = require('ethers');

/**
 * Generate a Merkle Tree from a list of Ethereum addresses
 * @param {string[]} addresses - List of Ethereum addresses
 * @returns {object} Merkle Tree and root
 */
function generateMerkleTree(addresses) {
  // Convert addresses to leaves
  const leaves = addresses.map(addr => 
    // Hash each address with keccak256
    keccak256(ethers.utils.defaultAbiCoder.encode(['address'], [addr]))
  );

  // Create Merkle Tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  const root = tree.getHexRoot();

  return { tree, root };
}

/**
 * Generate a Merkle proof for a specific address
 * @param {object} tree - Merkle Tree object
 * @param {string} address - Ethereum address to generate proof for
 * @returns {string[]} Merkle proof for the address
 */
function generateProof(tree, address) {
  const leaf = keccak256(ethers.utils.defaultAbiCoder.encode(['address'], [address]));
  return tree.getHexProof(leaf);
}

/**
 * Verify a Merkle proof
 * @param {string} root - Merkle root
 * @param {string[]} proof - Merkle proof
 * @param {string} address - Ethereum address to verify
 * @returns {boolean} True if proof is valid
 */
function verifyProof(root, proof, address) {
  const leaf = keccak256(ethers.utils.defaultAbiCoder.encode(['address'], [address]));
  return MerkleTree.verify(proof, leaf, root, keccak256, { sortPairs: true });
}

// Example usage
function example() {
  // Sample addresses
  const addresses = [
    '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
    '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',
    '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',
    '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB'
  ];

  console.log('Generating Merkle tree for addresses:', addresses);
  
  // Generate Merkle Tree
  const { tree, root } = generateMerkleTree(addresses);
  console.log('Merkle Root:', root);

  // Generate proof for the first address
  const addressToProve = addresses[0];
  const proof = generateProof(tree, addressToProve);
  console.log('Merkle Proof for', addressToProve, ':', proof);

  // Verify the proof
  const isValid = verifyProof(root, proof, addressToProve);
  console.log('Proof is valid:', isValid);

  // Try with an invalid address
  const invalidAddress = '0x1234567890123456789012345678901234567890';
  const isInvalidValid = verifyProof(root, proof, invalidAddress);
  console.log('Invalid proof is valid:', isInvalidValid);
}

// Export functions for use in other scripts
module.exports = {
  generateMerkleTree,
  generateProof,
  verifyProof,
  example
};

// Run example if this script is executed directly
if (require.main === module) {
  example();
} 