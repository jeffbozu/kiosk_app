import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla de login con email/contraseña, mensajes en español
/// y estilo de botón/título actualizado.
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para los TextFields
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _loading = false;  // Para mostrar el spinner
  String? _error;         // Mensaje de error a mostrar

  /// Lógica de inicio de sesión con Firebase Auth
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      // Intentar autenticar
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // TODO: Navegar a la pantalla principal
    } on FirebaseAuthException catch (e) {
      // Traducción de los códigos de error de FirebaseAuth
      switch (e.code) {
        case 'invalid-email':
          _error = 'La dirección de correo tiene un formato incorrecto.';
          break;
        case 'user-disabled':
          _error = 'La cuenta de usuario está desactivada.';
          break;
        case 'user-not-found':
          _error = 'No existe ningún usuario con ese correo.';
          break;
        case 'wrong-password':
          _error = 'Correo o contraseña incorrectos.';
          break;
        case 'too-many-requests':
          _error = 'Se han intentado demasiados accesos. Intenta más tarde.';
          break;
        case 'invalid-credential':
          _error = 'La credencial proporcionada es incorrecta o ha expirado.';
          break;
        default:
          _error = 'Error al iniciar sesión: ${e.message}';
      }
    } catch (e) {
      // Cualquier otro error
      _error = 'Ha ocurrido un error inesperado.';
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título de bienvenida
              Text(
                'Bienvenido a Meypar Optima App',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE62144), // Rojo marca
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de email
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo de contraseña
              TextField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),

              // Mensaje de error en rojo
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 16),

              // Botón de iniciar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            color: Colors.white,         // Texto blanco
                            fontWeight: FontWeight.bold,  // Negrita
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
