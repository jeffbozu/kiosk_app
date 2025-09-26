# APIs de RENDER.COM - Mock Mowiz

Este archivo contiene la información de las APIs de RENDER.COM utilizadas en el proyecto.

## Repositorio Base
- **Repositorio**: https://github.com/jeffbozu/mock_mowiz
- **Propietario**: jeffbozu

## APIs Disponibles

### 1. API Principal - Zonas
- **URL**: https://mock-mowiz.onrender.com
- **Rama**: `main`
- **Descripción**: API principal para gestión de zonas

### 2. API Tariff2
- **URL**: https://tariff2.onrender.com
- **Rama**: `tariff2`
- **Descripción**: API para gestión de tarifas

### 3. API Email
- **URL**: https://render-mail-2bzn.onrender.com
- **Rama**: `render-mail`
- **Descripción**: Servidor proxy para envío de emails de tickets de estacionamiento
- **Endpoints**:
  - `POST /api/send-email`: Enviar email con ticket
  - `POST /api/auto-reply`: Auto-respuesta para emails recibidos
  - `GET /health`: Estado del servidor
  - `GET /`: Información del servidor

### 4. API WhatsApp
- **URL**: https://render-whatsapp-tih4.onrender.com
- **Rama**: `render-whatsapp-only`
- **Descripción**: API para integración con WhatsApp

## Estado de las APIs (Verificación 26/09/2025 - ACTUALIZADO)

### ✅ APIs Funcionando:
- **API Email**: https://render-mail-2bzn.onrender.com - ✅ **FUNCIONANDO** (HTTP 200)
  - Endpoint `/health` responde correctamente
  - Servidor activo con uptime de 1145+ segundos
  - Versión: 2.0.0-optimized
  - **Rama**: `render-mail` - ✅ **CÓDIGO CORRECTO**

- **API Principal (Zonas)**: https://mock-mowiz.onrender.com - ✅ **FUNCIONANDO** (HTTP 200)
  - Endpoint `/v1/config` responde: `{"version":1,"apiBaseUrl":"https://mock-mowiz.onrender.com"}`
  - Endpoint `/v1/onstreet-service/zones` responde con zonas: coche, moto, camión
  - **Rama**: `main` - ✅ **CÓDIGO CORRECTO**

- **API Tariff2**: https://tariff2.onrender.com - ✅ **FUNCIONANDO** (HTTP 200)
  - Endpoint `/v1/config` responde: `{"version":1,"apiBaseUrl":"https://mock-mowiz.onrender.com"}`
  - Endpoint `/v1/onstreet-service/zones` responde con zonas: blue, green
  - **Rama**: `tariff2` - ✅ **CÓDIGO CORRECTO**

- **API WhatsApp**: https://render-whatsapp-tih4.onrender.com - ✅ **FUNCIONANDO** (HTTP 200)
  - Endpoint `/health` responde: `{"status":"OK","service":"WhatsApp Service","twilioConfigured":"9ae5742c4dbe88c9ca735a0fe13ae464","whatsappFrom":"whatsapp:+14155238886"}`
  - **Rama**: `render-whatsapp-only` - ✅ **CÓDIGO CORRECTO**

### ❌ APIs con Problemas:
**¡TODAS LAS APIs ESTÁN FUNCIONANDO!** 🎉

## Análisis del Código

### Configuración de la App Flutter:
- **API Base URL por defecto**: `https://mock-mowiz.onrender.com` (lib/api_config.dart)
- **ConfigService**: Intenta cargar configuración desde `/v1/config` al iniciar
- **MowizPayPage**: Usa diferentes URLs según la empresa:
  - MOWIZ: `https://tariff2.onrender.com/v1/onstreet-service/zones`
  - EYPSA: `${ConfigService.apiBaseUrl}/v1/onstreet-service/zones`

### Servidores Analizados:
1. **Rama `main`**: Servidor Express con zonas (coche, moto, camión) - Puerto 3001
2. **Rama `tariff2`**: Servidor Express con zonas (blue, green) - Puerto 3001  
3. **Rama `render-mail`**: Servidor de email completo - Puerto 4000 ✅ **FUNCIONANDO**
4. **Rama `render-whatsapp-only`**: Servidor de email + WhatsApp - Puerto 4000

## Problema Identificado - RESUELTO ✅
- **TODAS LAS APIs ESTÁN FUNCIONANDO** en RENDER.COM
- **4/4 APIs activas y respondiendo correctamente**
- Los servidores están ejecutándose en producción

## Estado Final
✅ **Sistema completamente operativo**
- API Principal: Funcionando con zonas (coche, moto, camión)
- API Tariff2: Funcionando con zonas (blue, green)  
- API Email: Funcionando con envío de emails
- API WhatsApp: Funcionando con Twilio configurado

## Notas
- El repositorio mock_mowiz contiene el código fuente de todos los servicios
- Última verificación: 26/09/2025 14:00 UTC
- Flutter web ejecutándose en puerto 8081 (puerto 8080 ocupado)
