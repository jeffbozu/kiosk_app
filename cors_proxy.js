// Proxy CORS simple para desarrollo
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const app = express();

// Configurar CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Proxy para la API de Render - usando la API principal que tiene los endpoints de configuración
app.use('/api', createProxyMiddleware({
  target: 'https://mock-mowiz.onrender.com', // API principal con endpoints de configuración
  changeOrigin: true,
  pathRewrite: {
    '^/api': '', // remove /api prefix
  },
}));

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`CORS Proxy running on http://localhost:${PORT}`);
});
