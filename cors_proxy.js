const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = 3001;

// Configurar CORS para permitir todas las peticiones
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: false
}));

// Proxy para la API principal
app.use('/api', createProxyMiddleware({
  target: 'https://mock-mowiz.onrender.com',
  changeOrigin: true,
  pathRewrite: {
    '^/api': '', // Remover /api del path
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`🔄 API Proxy: ${req.method} ${req.url} -> https://mock-mowiz.onrender.com${req.url.replace('/api', '')}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`✅ API Response: ${proxyRes.statusCode} ${req.url}`);
  },
  onError: (err, req, res) => {
    console.log(`❌ API Error: ${err.message}`);
  }
}));

// Proxy para WhatsApp
app.use('/whatsapp', createProxyMiddleware({
  target: 'https://render-whatsapp-tih4.onrender.com',
  changeOrigin: true,
  pathRewrite: {
    '^/whatsapp': '/whatsapp', // Mantener /whatsapp en el path
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`📱 WhatsApp Proxy: ${req.method} ${req.url} -> https://render-whatsapp-tih4.onrender.com${req.url}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`✅ WhatsApp Response: ${proxyRes.statusCode} ${req.url}`);
  },
  onError: (err, req, res) => {
    console.log(`❌ WhatsApp Error: ${err.message}`);
  }
}));

// Proxy para Email
app.use('/email', createProxyMiddleware({
  target: 'https://render-mail-2bzn.onrender.com',
  changeOrigin: true,
  pathRewrite: {
    '^/email': '', // Remover /email del path
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`📧 Email Proxy: ${req.method} ${req.url} -> https://render-mail-2bzn.onrender.com${req.url.replace('/email', '')}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`✅ Email Response: ${proxyRes.statusCode} ${req.url}`);
  },
  onError: (err, req, res) => {
    console.log(`❌ Email Error: ${err.message}`);
  }
}));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    services: {
      api: 'https://mock-mowiz.onrender.com',
      whatsapp: 'https://render-whatsapp-tih4.onrender.com',
      email: 'https://render-mail-2bzn.onrender.com'
    }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 CORS Proxy running on http://localhost:${PORT}`);
  console.log(`📡 API Proxy: http://localhost:${PORT}/api -> https://mock-mowiz.onrender.com`);
  console.log(`📱 WhatsApp Proxy: http://localhost:${PORT}/whatsapp -> https://render-whatsapp-tih4.onrender.com`);
  console.log(`📧 Email Proxy: http://localhost:${PORT}/email -> https://render-mail-2bzn.onrender.com`);
  console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
});
