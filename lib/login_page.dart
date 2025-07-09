import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

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
      final l = AppLocalizations.of(context);
      switch (e.code) {
        case 'invalid-email':
          _error = l.t('invalidEmail');
          break;
        case 'user-disabled':
          _error = l.t('userDisabled');
          break;
        case 'user-not-found':
          _error = l.t('userNotFound');
          break;
        case 'wrong-password':
          _error = l.t('wrongPassword');
          break;
        case 'too-many-requests':
          _error = l.t('tooManyRequests');
          break;
        case 'invalid-credential':
          _error = l.t('invalidCredential');
          break;
        default:
          _error = l.t('loginError', params: {'error': e.message ?? ''});
      }
    } catch (e) {
      // Cualquier otro error
      final l = AppLocalizations.of(context);
      _error = l.t('unexpectedError');
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
              Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    LanguageSelector(),
                    SizedBox(width: 8),
                    ThemeModeButton(),
                  ],
                ),
              ),
              // Título de bienvenida
              Text(
                AppLocalizations.of(context).t('welcome'),
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
                  labelText: AppLocalizations.of(context).t('email'),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo de contraseña
              TextField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).t('password'),
                  prefixIcon: const Icon(Icons.lock),
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
                      : Text(AppLocalizations.of(context).t('signIn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
