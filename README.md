# kiosk_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuración dinámica del QR

La lista de campos que aparecen en el código QR **no está en el código**.
Para modificarla accede a Firestore y edita el documento
`settings/qrConfig`:

1. Abre la consola de Firebase y navega a **Firestore**.
2. Ve a la colección `settings` y abre el documento `qrConfig`.
   Asegúrate de escribirlo exactamente con esa mayúscula; el nombre es
   sensible a mayúsculas y minúsculas.
3. Edita el array `qrFields` para añadir, quitar o reordenar los nombres de
   los campos del ticket que quieras mostrar.
4. Guarda los cambios. La app leerá este array al generar cada QR y reflejará
   la modificación sin desplegar una nueva versión.

Ejemplo de valores para `qrFields`:

```json
["plate", "status"]
```

```json
["plate", "paidUntil", "paymentMethod"]
```

**No modifiques el código para cambiar estos campos;** solamente actualiza el
array `qrFields` en Firestore.
