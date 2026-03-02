import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _alertPlayer = AudioPlayer();

  void playNewKitchenOrder() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/nuevo_pedido_cocina.mp3'));
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      print('Error reproduciendo sonido cocina: $e');
    }
  }

  void playNewDeliveryOrder() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/nuevo_pedido_cocina.mp3'));
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      print('Error reproduciendo sonido delivery: $e');
    }
  }

  int _activeAlarms = 0;

  void playTimerAlarm() async {
    try {
      _activeAlarms++;
      if (_activeAlarms == 1) {
        await _alertPlayer.setReleaseMode(ReleaseMode.loop);
        await _alertPlayer.play(AssetSource('sounds/SonidoTemporizador.mp3'));
      }
    } catch (e) {
      print('Error reproduciendo alarma: $e');
    }
  }

  void stopTimerAlarm() async {
    try {
      if (_activeAlarms > 0) _activeAlarms--;
      if (_activeAlarms == 0) {
        await _alertPlayer.stop();
      }
    } catch (e) {
      print('Error deteniendo alarma: $e');
    }
  }
}
