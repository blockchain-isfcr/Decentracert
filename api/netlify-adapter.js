// Load environment variables
require('dotenv').config();

// Import the Express app
const app = require('../backend/src/app');

// Export the Netlify serverless function handler
exports.handler = async (event, context) => {
  // Create a mock request object for Express
  const req = {
    method: event.httpMethod,
    headers: event.headers,
    url: event.path.replace('/.netlify/functions/api', ''),
    body: event.body ? JSON.parse(event.body) : {},
    params: {},
    query: event.queryStringParameters || {},
  };

  // Create a mock response object for Express
  const res = {
    statusCode: 200,
    headers: {},
    body: '',
    status: function (code) {
      this.statusCode = code;
      return this;
    },
    json: function (data) {
      this.headers['Content-Type'] = 'application/json';
      this.body = JSON.stringify(data);
      return this;
    },
    send: function (data) {
      this.body = data;
      return this;
    },
    end: function () {
      return this;
    },
    set: function (key, value) {
      this.headers[key] = value;
      return this;
    },
  };

  // Process the request through Express
  return new Promise((resolve, reject) => {
    app._router.handle(req, res, (err) => {
      if (err) {
        resolve({
          statusCode: 500,
          body: JSON.stringify({ error: err.message }),
          headers: { 'Content-Type': 'application/json' },
        });
      } else {
        resolve({
          statusCode: res.statusCode,
          body: res.body,
          headers: res.headers,
        });
      }
    });
  });
}; 