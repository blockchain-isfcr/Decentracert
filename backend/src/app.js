const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const issuerRoutes = require('./routes/issuers');
const certificateRoutes = require('./routes/certificates');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Health check
app.get('/health', (_, res) => {
  return res.json({ status: 'ok', timestamp: Date.now() });
});

// API Routes
app.use('/api/issuer', issuerRoutes);
app.use('/api/certificate', certificateRoutes);

// 404 handler
app.use('*', (_, res) => {
  return res.status(404).json({ error: 'Not found' });
});

module.exports = app; 