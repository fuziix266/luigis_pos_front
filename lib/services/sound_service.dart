import 'dart:html' as html;

class SoundService {
  html.AudioElement? _alertAudio;

  void playNewKitchenOrder() {
    try {
      final audio = html.AudioElement('assets/sounds/nuevo_pedido_cocina.mp3');
      audio.play();
    } catch (e) {
      print('Error reproduciendo sonido cocina: $e');
    }
  }

  void playNewDeliveryOrder() {
    try {
      final audio = html.AudioElement('assets/sounds/nuevo_pedido_cocina.mp3');
      audio.play();
    } catch (e) {
      print('Error reproduciendo sonido delivery: $e');
    }
  }

  int _activeAlarms = 0;

  void playTimerAlarm() {
    try {
      _activeAlarms++;
      if (_alertAudio == null) {
        _alertAudio = html.AudioElement('assets/sounds/SonidoTemporizador.mp3');
        _alertAudio!.loop = true;
      }
      _alertAudio!.play();
    } catch (e) {
      print('Error reproduciendo alarma: $e');
    }
  }

  void stopTimerAlarm() {
    try {
      if (_activeAlarms > 0) _activeAlarms--;
      if (_activeAlarms == 0) {
        _alertAudio?.pause();
        _alertAudio?.currentTime = 0;
      }
    } catch (e) {
      print('Error deteniendo alarma: $e');
    }
  }
}
