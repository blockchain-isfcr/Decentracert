# Vercel Deployment Guide for DecentraCert

This guide explains how to deploy the DecentraCert application to Vercel and avoid common issues like the 404 NOT_FOUND error.

## Key Files Modified

1. **vercel.json** (root) - Updated with proper routing configuration
   - Configured builds for both frontend and backend
   - Set up routes to correctly handle API calls and SPA routes

2. **frontend/package.json** - Added homepage field
   - Added `"homepage": "."` to ensure correct path resolution

3. **frontend/public/vercel.json** - Added SPA routing configuration
   - Added rewrites rule to handle client-side routing

## Environment Variables

Make sure to set up these environment variables in your Vercel project settings:

```
INFURA_API_KEY=e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
PRIVATE_KEY=be659c3aadb144e296b327d3a065a97f
CMC_API_KEY=88648bc5-03a8-45f3-81ad-701aa241443c
REPORT_GAS=true
PORT=3001
NETWORK=sepolia
RPC_URL=https://sepolia.infura.io/v3/e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
```

## Deployment Steps

1. **Connect your repository to Vercel**:
   - Log in to Vercel and import your GitHub repository

2. **Configure the build settings**:
   - Framework preset: Other
   - Build Command: `npm run build`
   - Output Directory: `frontend/build`
   - Install Command: `npm install`

3. **Set environment variables**:
   - Go to Settings > Environment Variables
   - Add all the required environment variables listed above

4. **Deploy!**:
   - Click "Deploy" and wait for the build to complete

## Troubleshooting

If you still encounter 404 errors:

1. Check Vercel build logs for any errors
2. Verify that the vercel.json files are correctly placed
3. Try redeploying after clearing the Vercel cache
4. Make sure all environment variables are set correctly

## Local Testing

To test the production build locally before deploying:

```bash
cd frontend
npm run build
npx serve -s build
```

This will serve your production build on http://localhost:3000 for testing.