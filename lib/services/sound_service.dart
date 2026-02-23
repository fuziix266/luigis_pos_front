import 'dart:html' as html;

class SoundService {
  void playNewKitchenOrder() {
    try {
      final audio = html.AudioElement('assets/sounds/nuevo_pedido_cocina.mp3');
      audio.play();
    } catch (e) {
      print('Error reproduciendo sonido: $e');
    }
  }
}
