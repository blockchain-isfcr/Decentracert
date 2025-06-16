// Entry point for DecentraCert++ backend API
require('dotenv').config();

const app = require('./app');

const PORT = process.env.PORT || 3001;

if (!process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`🚀 Backend API listening on http://localhost:${PORT}`);
  });
} 