# Netlify Deployment Guide for DecentraCert

If you're experiencing issues with Vercel deployment, this guide provides an alternative approach using Netlify.

## Files Created for Netlify

1. **netlify.toml** - Main configuration file
   - Configures build settings
   - Sets up redirects for SPA routing
   - Configures serverless functions

2. **api/netlify-adapter.js** - Adapter for Express API
   - Translates between Netlify serverless functions and Express

## Environment Variables

Set up these environment variables in your Netlify project settings:

```
INFURA_API_KEY=e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
PRIVATE_KEY=0xbe659c3aadb144e296b327d3a065a97f
CMC_API_KEY=88648bc5-03a8-45f3-81ad-701aa241443c
REPORT_GAS=true
PORT=3001
NETWORK=sepolia
RPC_URL=https://sepolia.infura.io/v3/e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
```

## Deployment Steps

1. **Sign up for Netlify**:
   - Create an account on [netlify.com](https://netlify.com) if you don't have one

2. **Connect your repository**:
   - Go to the Netlify dashboard
   - Click "New site from Git"
   - Choose your Git provider (GitHub, GitLab, or Bitbucket)
   - Select your repository

3. **Configure build settings**:
   - Build command: `npm run build`
   - Publish directory: `frontend/build`

4. **Set environment variables**:
   - Go to Site settings > Build & deploy > Environment
   - Add all the required environment variables listed above

5. **Deploy**:
   - Click "Deploy site"

## API Access

When using Netlify, your API endpoints will be available at:

```
https://your-site-name.netlify.app/.netlify/functions/api/...
```

For example, to access the health check endpoint:

```
https://your-site-name.netlify.app/.netlify/functions/api/health
```

## Troubleshooting

If you encounter issues:

1. Check the Netlify deploy logs
2. Ensure the netlify.toml file is in the root directory
3. Verify all environment variables are set
4. Check Functions tab in Netlify dashboard for function deployment status

## Local Testing with Netlify CLI

To test locally:

```bash
# Install Netlify CLI
npm install netlify-cli -g

# Run the Netlify dev environment
netlify dev
```

This will start both your frontend and backend locally, simulating the Netlify environment. 