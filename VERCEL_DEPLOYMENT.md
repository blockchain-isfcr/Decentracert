# Vercel Deployment Guide for DecentraCert

This guide explains how to deploy the DecentraCert application to Vercel and avoid common issues like the 404 NOT_FOUND error.

## Key Files Modified

1. **vercel.json** (root) - Updated with proper routing configuration
   - Configured builds for both frontend and backend
   - Changed from "routes" to "rewrites" for simpler SPA routing

2. **api/vercel.json** - Added specific file inclusion for API deployment
   - Ensures all necessary backend files are included in the serverless function

3. **frontend/package.json** - Added homepage field
   - Added `"homepage": "."` to ensure correct path resolution

4. **frontend/public/vercel.json** - Added SPA routing configuration
   - Added rewrites rule to handle client-side routing

5. **api/index.js** - Updated to load environment variables
   - Added dotenv configuration to ensure API has access to required variables

## Environment Variables

Make sure to set up these environment variables in your Vercel project settings:

```
INFURA_API_KEY=e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
PRIVATE_KEY=0xbe659c3aadb144e296b327d3a065a97f
CMC_API_KEY=88648bc5-03a8-45f3-81ad-701aa241443c
REPORT_GAS=true
PORT=3001
NETWORK=sepolia
RPC_URL=https://sepolia.infura.io/v3/e2a4fc3f15ae0cca28bbe1aedaf41c5a545962422466dcc0de0e0bc92bbdee5e
```

## Important Notes

1. The warning message "WARN! Due to `builds` existing in your configuration file..." is expected and not an issue. It just means your Vercel UI build settings are ignored in favor of the settings in vercel.json.

2. For React Router to work correctly, we've configured:
   - A root vercel.json that uses the "rewrites" pattern instead of "routes"
   - A secondary vercel.json in the frontend/public directory as an additional safeguard

## Deployment Steps

1. **Connect your repository to Vercel**:
   - Log in to Vercel and import your GitHub repository

2. **Set environment variables**:
   - Go to Settings > Environment Variables
   - Add all the required environment variables listed above

3. **Deploy!**:
   - Click "Deploy" and wait for the build to complete

## Troubleshooting

If you still encounter 404 errors:

1. Check Vercel build logs for any errors
2. Try removing the "rewrites" section from vercel.json and use only the frontend/public/vercel.json
3. Try updating the output directory in Vercel UI to just "build" (even though this will be ignored)
4. Make sure all environment variables are set correctly
5. Check if the API endpoints are working by testing a direct API URL like https://yourdomain.vercel.app/api/health

## Local Testing

To test the production build locally before deploying:

```bash
cd frontend
npm run build
npx serve -s build
```

For API testing, run:
```bash
cd backend
npm run dev
```

This will serve your API on http://localhost:3001 for testing.