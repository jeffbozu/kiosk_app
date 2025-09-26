# 🚀 Guía de Despliegue de APIs en RENDER.COM

## 📋 **Resumen del Problema**
- **3 de 4 APIs no están desplegadas** en RENDER.COM
- Solo la API de Email está funcionando
- Necesitas desplegar las APIs faltantes

## 🎯 **APIs que Necesitan Despliegue**

### 1. **API Principal (mock-mowiz.onrender.com)**
- **Rama**: `main`
- **Puerto**: 3001
- **Descripción**: API principal con zonas (coche, moto, camión)

### 2. **API Tariff2 (tariff2.onrender.com)**
- **Rama**: `tariff2` 
- **Puerto**: 3001
- **Descripción**: API con zonas (blue, green)

### 3. **API WhatsApp (render-whatsapp-tih4.onrender.com)**
- **Rama**: `render-whatsapp-only`
- **Puerto**: 4000
- **Descripción**: API de WhatsApp + Email

## 🛠️ **Pasos para Desplegar en RENDER.COM**

### **Paso 1: Preparar el Repositorio**

1. **Ir a GitHub**: https://github.com/jeffbozu/mock_mowiz
2. **Verificar que las ramas estén actualizadas**:
   - `main` ✅
   - `tariff2` ✅  
   - `render-mail` ✅ (ya funcionando)
   - `render-whatsapp-only` ✅

### **Paso 2: Desplegar API Principal (mock-mowiz.onrender.com)**

1. **Ir a RENDER.COM** → Dashboard
2. **Crear nuevo Web Service**:
   - **Name**: `mock-mowiz`
   - **Repository**: `https://github.com/jeffbozu/mock_mowiz`
   - **Branch**: `main`
   - **Root Directory**: `/` (raíz)
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Port**: `3001`

3. **Variables de Entorno** (si es necesario):
   - `NODE_ENV=production`
   - `PORT=3001`

### **Paso 3: Desplegar API Tariff2 (tariff2.onrender.com)**

1. **Crear nuevo Web Service**:
   - **Name**: `tariff2`
   - **Repository**: `https://github.com/jeffbozu/mock_mowiz`
   - **Branch**: `tariff2`
   - **Root Directory**: `/` (raíz)
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Port**: `3001`

2. **Variables de Entorno**:
   - `NODE_ENV=production`
   - `PORT=3001`

### **Paso 4: Desplegar API WhatsApp (render-whatsapp-tih4.onrender.com)**

1. **Crear nuevo Web Service**:
   - **Name**: `render-whatsapp-tih4`
   - **Repository**: `https://github.com/jeffbozu/mock_mowiz`
   - **Branch**: `render-whatsapp-only`
   - **Root Directory**: `/` (raíz)
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Port**: `4000`

2. **Variables de Entorno**:
   - `NODE_ENV=production`
   - `PORT=4000`
   - `GMAIL_EMAIL=tu-email@gmail.com`
   - `GMAIL_PASSWORD=tu-app-password`

## 🔧 **Configuración Específica por API**

### **API Principal (main)**
```javascript
// server.js - Puerto 3001
const PORT = process.env.PORT || 3001;
// Endpoints: /v1/config, /v1/onstreet-service/zones
```

### **API Tariff2 (tariff2)**
```javascript
// server.js - Puerto 3001  
const PORT = process.env.PORT || 3001;
// Endpoints: /v1/config, /v1/onstreet-service/zones
// Zonas: blue, green
```

### **API WhatsApp (render-whatsapp-only)**
```javascript
// server.js - Puerto 4000
const PORT = process.env.PORT || 4000;
// Endpoints: /api/send-email, /api/auto-reply, /health
```

## ✅ **Verificación Post-Despliegue**

### **1. Verificar API Principal**
```bash
curl https://mock-mowiz.onrender.com/v1/config
curl https://mock-mowiz.onrender.com/v1/onstreet-service/zones
```

### **2. Verificar API Tariff2**
```bash
curl https://tariff2.onrender.com/v1/config
curl https://tariff2.onrender.com/v1/onstreet-service/zones
```

### **3. Verificar API WhatsApp**
```bash
curl https://render-whatsapp-tih4.onrender.com/health
curl https://render-whatsapp-tih4.onrender.com/
```

## 🚨 **Problemas Comunes y Soluciones**

### **Error 404 - Servicio no encontrado**
- **Causa**: Servicio no desplegado o no iniciado
- **Solución**: Verificar que el servicio esté "Live" en RENDER.COM

### **Error de Puerto**
- **Causa**: Puerto incorrecto en configuración
- **Solución**: Usar `process.env.PORT` en el código

### **Error de Dependencias**
- **Causa**: package.json incompleto
- **Solución**: Verificar que package.json tenga scripts de start

## 📱 **Configuración en Flutter App**

Una vez desplegadas las APIs, la app Flutter debería funcionar automáticamente:

- **ConfigService**: Cargará configuración desde `/v1/config`
- **MowizPayPage**: Usará las URLs correctas según la empresa
- **Email Service**: Usará la API de email funcionando

## 🎯 **Resultado Esperado**

Después del despliegue:
- ✅ **4/4 APIs funcionando**
- ✅ **App Flutter conectada a todas las APIs**
- ✅ **Sistema completo operativo**

## 📞 **Soporte**

Si tienes problemas con el despliegue:
1. Verificar logs en RENDER.COM
2. Comprobar variables de entorno
3. Verificar que el repositorio esté actualizado
4. Revisar que las ramas tengan el código correcto

---
**Última actualización**: 26/09/2025
**Estado**: 1/4 APIs funcionando, 3/4 pendientes de despliegue
