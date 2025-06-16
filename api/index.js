// Load environment variables
require('dotenv').config();

// Import the app
const app = require('../backend/src/app');

// Export the app for Vercel serverless deployment
module.exports = app; 