# 🔧 Instrucciones para Hacer Push del Fix de CORS

## 🚨 **Problema:**
El push falló porque necesita autenticación de GitHub. RENDER.COM depende de la rama remota.

## ✅ **Solución - Haz el Push Manualmente:**

### **1. Ir al directorio del repositorio:**
```bash
cd /home/jeffrey/kioskapp/mock_mowiz
```

### **2. Verificar el estado:**
```bash
git status
git log --oneline -3
```

### **3. Hacer push con token de GitHub:**
```bash
git push origin render-whatsapp-only
```

**Cuando te pida credenciales:**
- **Username**: `jeffbozu`
- **Password**: Usa un **Personal Access Token** de GitHub (NO tu contraseña)

### **4. Si no tienes token, crear uno:**
1. Ir a GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Seleccionar scopes: `repo` (Full control of private repositories)
4. Copiar el token generado
5. Usar ese token como password en el push

## 🔍 **Verificar que el Push Funcionó:**

### **1. Verificar en GitHub:**
- Ir a https://github.com/jeffbozu/mock_mowiz
- Cambiar a la rama `render-whatsapp-only`
- Verificar que el commit `Fix CORS for localhost:8081 in WhatsApp service` esté presente

### **2. Verificar en RENDER.COM:**
- Ir a tu dashboard de RENDER.COM
- Buscar el servicio `render-whatsapp-tih4`
- Verificar que se haya desplegado automáticamente
- Revisar los logs para confirmar que el nuevo código está activo

## 🧪 **Test Final:**

### **1. Probar desde la app Flutter:**
- Abrir http://localhost:8081
- Intentar enviar un WhatsApp
- Verificar que NO aparezca el error de CORS

### **2. Probar con curl:**
```bash
curl -X POST https://render-whatsapp-tih4.onrender.com/v1/whatsapp/send \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8081" \
  -d '{"phone":"+34678395045","ticket":{"plate":"123456","zone":"coche","start":"26/09/2025 17:15","end":"26/09/2025 17:23","duration":"8m","price":0.2,"discount":null,"method":"qr","qrData":null},"localeCode":"es"}'
```

## 📝 **Cambios Realizados:**

### **Archivo modificado:** `server/index.js`
### **Líneas agregadas:**
```javascript
'http://localhost:8081',    // ✅ AGREGADO
'http://localhost:9001',    // ✅ AGREGADO
'http://127.0.0.1:8080',    // ✅ AGREGADO
'http://127.0.0.1:8081',    // ✅ AGREGADO
'http://127.0.0.1:9001'     // ✅ AGREGADO
```

## 🎯 **Resultado Esperado:**
- ✅ **Push exitoso** a la rama `render-whatsapp-only`
- ✅ **RENDER.COM se despliega automáticamente** con el nuevo código
- ✅ **CORS configurado** para `localhost:8081`
- ✅ **WhatsApp funciona** desde la app Flutter sin errores de CORS

---
**¡Una vez hecho el push, el problema de CORS estará completamente resuelto!** 🎉
