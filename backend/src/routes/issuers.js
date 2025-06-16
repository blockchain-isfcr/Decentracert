const express = require('express');
const { ethers } = require('ethers');
const { getContracts } = require('../services/contracts');

const router = express.Router();

/**
 * Middleware to attach contract instances
 */
router.use(async (req, res, next) => {
  try {
    const { issuerRegistry } = await getContracts();
    req.issuerRegistry = issuerRegistry;
    next();
  } catch (err) {
    console.error('Error connecting to IssuerRegistry:', err);
    return res.status(500).json({ error: 'IssuerRegistry connection failed' });
  }
});

/**
 * POST /api/issuer/verify/t1
 * body: { issuerName, domain, verificationData }
 */
router.post('/verify/t1', async (req, res) => {
  const { issuerName, domain, verificationData } = req.body;
  if (!issuerName || !domain) return res.status(400).json({ error: 'issuerName and domain required' });

  try {
    const tx = await req.issuerRegistry.verifyIssuerT1(issuerName, domain, verificationData || '');
    await tx.wait();
    return res.json({ status: 'submitted', txHash: tx.hash });
  } catch (err) {
    console.error('verifyIssuerT1 error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

/**
 * POST /api/issuer/verify/t2
 * body: { issuerName, socialMediaUrl }
 */
router.post('/verify/t2', async (req, res) => {
  const { issuerName, socialMediaUrl } = req.body;
  if (!issuerName || !socialMediaUrl) return res.status(400).json({ error: 'issuerName and socialMediaUrl required' });

  try {
    const tx = await req.issuerRegistry.verifyIssuerT2(issuerName, socialMediaUrl);
    await tx.wait();
    return res.json({ status: 'submitted', txHash: tx.hash });
  } catch (err) {
    console.error('verifyIssuerT2 error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

/**
 * POST /api/issuer/verify/manual
 * body: { issuerAddress, issuerName }
 * Only owner admin wallet should call; this backend server ensures only owner wallet key in env is used.
 */
router.post('/verify/manual', async (req, res) => {
  const { issuerAddress, issuerName } = req.body;
  if (!issuerAddress || !issuerName) return res.status(400).json({ error: 'issuerAddress and issuerName required' });

  try {
    const tx = await req.issuerRegistry.manualVerifyIssuer(issuerAddress, issuerName);
    await tx.wait();
    return res.json({ status: 'submitted', txHash: tx.hash });
  } catch (err) {
    console.error('manualVerifyIssuer error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

/**
 * POST /api/issuer/upgrade
 * body: { domain, verificationData }
 */
router.post('/upgrade', async (req, res) => {
  const { domain, verificationData } = req.body;
  if (!domain) return res.status(400).json({ error: 'domain required' });

  try {
    const tx = await req.issuerRegistry.upgradeToT1(domain, verificationData || '');
    await tx.wait();
    return res.json({ status: 'submitted', txHash: tx.hash });
  } catch (err) {
    console.error('upgradeToT1 error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

/**
 * GET /api/issuer/:address
 * returns IssuerData struct
 */
router.get('/:address', async (req, res) => {
  const { address } = req.params;
  try {
    const data = await req.issuerRegistry.getIssuerData(address);
    return res.json(data);
  } catch (err) {
    console.error('fetch issuer data error:', err);
    return res.status(500).json({ error: err.reason || err.message });
  }
});

module.exports = router; 