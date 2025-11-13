require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const ELECTRIC_URL = process.env.ELECTRIC_URL || 'http://localhost:5133';
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISSUER = process.env.JWT_ISSUER || 'sertantai_controls';

if (!JWT_SECRET) {
  console.error('ERROR: JWT_SECRET environment variable is required');
  process.exit(1);
}

// Enable CORS
app.use(cors());

// Middleware to validate JWT and shape claims
const validateShapeToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = req.query.token || (authHeader && authHeader.split(' ')[1]);

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    // Verify JWT
    const decoded = jwt.verify(token, JWT_SECRET, {
      issuer: JWT_ISSUER
    });

    // Extract shape claim
    const shapeClaim = decoded.shape;
    if (!shapeClaim) {
      return res.status(403).json({ error: 'No shape claim in token' });
    }

    // Validate shape parameters match token claim
    const requestedTable = req.query.table;
    const requestedWhere = req.query.where || '';

    if (requestedTable !== shapeClaim.table) {
      return res.status(403).json({
        error: 'Table parameter does not match token shape claim',
        requested: requestedTable,
        authorized: shapeClaim.table
      });
    }

    if (requestedWhere !== shapeClaim.where) {
      return res.status(403).json({
        error: 'Where clause does not match token shape claim',
        requested: requestedWhere,
        authorized: shapeClaim.where
      });
    }

    // Add user info to request for logging
    req.userId = decoded.sub;
    req.shapeClaim = shapeClaim;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    console.error('Token validation error:', error);
    return res.status(500).json({ error: 'Token validation failed' });
  }
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'electric-proxy' });
});

// Proxy Electric requests with validation
app.use('/v1/shape', validateShapeToken, createProxyMiddleware({
  target: ELECTRIC_URL,
  changeOrigin: true,
  ws: true, // Enable WebSocket proxying
  onProxyReq: (proxyReq, req) => {
    // Add user context header for logging
    proxyReq.setHeader('X-User-Id', req.userId);
    console.log(`[PROXY] User ${req.userId} accessing shape: ${req.shapeClaim.table}`);
  },
  onError: (err, req, res) => {
    console.error('[PROXY] Error:', err);
    res.status(500).json({ error: 'Proxy error', message: err.message });
  }
}));

// Start server
app.listen(PORT, () => {
  console.log(`Electric authorizing proxy listening on port ${PORT}`);
  console.log(`Proxying to Electric at: ${ELECTRIC_URL}`);
  console.log(`JWT Issuer: ${JWT_ISSUER}`);
});
