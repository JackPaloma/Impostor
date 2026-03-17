import 'package:flutter/services.dart';

class Sonidos {
  static void playClick() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  static void playTick() {
    SystemSound.play(SystemSoundType.click);
  }

  static void playReveal() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
  }
}


//aaaaa