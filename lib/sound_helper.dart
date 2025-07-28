import 'package:audioplayers/audioplayers.dart';

/// Helper para reproducir sonidos en la app.
/// Se ha diseñado para ser fácilmente extensible con más efectos de audio.
class SoundHelper {
  // Constructor privado para evitar instancias
  SoundHelper._();

  /// Reproductor para el sonido de tap. Se mantiene en memoria para
  /// reducir la latencia al pulsar un botón.
  static final AudioPlayer _tapPlayer =
      AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  /// Ruta del sonido de tap dentro de assets.
  static const String _tapAsset = 'sound/start.mp3';

  /// Reproduce el sonido de tap. Se llama al pulsar cualquier botón.
  static Future<void> playTap() async {
    try {
      // Si el sonido estaba sonando, lo reiniciamos para reproducirlo de nuevo
      await _tapPlayer.stop();
    } catch (_) {
      // Ignoramos cualquier error al detener
    }
    await _tapPlayer.play(AssetSource(_tapAsset));
  }

  // Aquí podrían añadirse métodos como `playSuccess()` o `playError()` usando
  // otros AudioPlayer si fuese necesario en el futuro.
}
