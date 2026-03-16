import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Color por defecto (Naranjo Pastel)
  static const Color primaryDefault = Color(0xFFFFB74D);

  // --- LISTA ORDENADA POR GAMA CROMÁTICA ---
  static final List<Color> colors = [
    const Color(0xFFFF4B4B), // Rojo (Duo Red)
    const Color(0xFFFFB74D), // Naranjo Pastel (Nuevo Default)
    const Color(0xFFF0932B), // Naranja Zanahoria
    const Color(0xFFFF9600), // Naranja Brillante
    const Color(0xFFFFD421), // Amarillo (Duo Yellow)
    const Color(0xFFC6FF00), // Lima Ácido
    const Color(0xFF21FF5F), // Verde Tóxico
    const Color(0xFF00E676), // Verde Teal
    const Color(0xFF21D4FD), // Cian (Original)
    const Color(0xFF2962FF), // Azul Eléctrico
    const Color(0xFF651FFF), // Violeta Oscuro
    const Color(0xFFB721FF), // Violeta Brillante
    const Color(0xFFFF2171), // Rosa Fuerte
  ];

  static Color primary = primaryDefault;
  static bool sonidoActivado = true;
  static final ValueNotifier<Color> colorNotifier = ValueNotifier(primaryDefault);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    int? colorValue = prefs.getInt('theme_color');
    if (colorValue != null) {
      primary = Color(colorValue);
      colorNotifier.value = primary;
    }

    sonidoActivado = prefs.getBool('app_sound_enabled') ?? true;
  }

  static void setColor(Color color) async {
    primary = color;
    colorNotifier.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.value);
  }

  static void toggleSound() async {
    sonidoActivado = !sonidoActivado;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_sound_enabled', sonidoActivado);
  }
}

// Estilos globales
const Color duoBg = Color(0xFF131F24);
const Color duoSurface = Color(0xFF182B32);
const Color duoBorder = Color(0xFF2A3A44);
const Color duoTextMain = Color(0xFFE5F5F3);
const Color duoTextSub = Color(0xFF6F8CA0);
const Color duoRed = Color(0xFFFF4B4B);
const Color duoBlue = Color(0xFF21D4FD);
const Color duoYellow = Color(0xFFFFD421);
const Color duoCream = Color(0xFFFAF8F1); // <--- BLANCO BEIGE MÁS CLARO

TextStyle duoFont({double size = 16, Color color = duoTextMain, FontWeight weight = FontWeight.w900}) {
  return TextStyle(
    fontFamily: 'Avenir',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: 1.2,
  );
}