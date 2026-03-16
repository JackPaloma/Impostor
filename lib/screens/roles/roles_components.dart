import 'package:flutter/material.dart';
import 'dart:io'; // <--- Necesario para leer la foto del dispositivo
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'roles_colors.dart';

// 1. BOTÓN DORADO GENÉRICO PARA EL JUEGO
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GoldButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: lobbyGold,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6))],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Color(0xFF2A1B0E), // Texto oscuro
            ),
          ),
        ),
      ),
    );
  }
}

// 2. PANTALLA DE TRANSICIÓN (PÁSALE EL TELÉFONO)
class PantallaTransicion extends StatelessWidget {
  final String nombreJugador;
  final String? rutaFoto; // <--- Recibe la foto del jugador
  final VoidCallback onListo;

  const PantallaTransicion({
    super.key,
    required this.nombreJugador,
    this.rutaFoto,
    required this.onListo
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 📸 AVATAR O HUELLA DACTILAR
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ebonyInput,
              border: Border.all(color: lobbyGoldDark, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
              // Si hay foto, la mostramos aquí
              image: rutaFoto != null
                  ? DecorationImage(
                image: FileImage(File(rutaFoto!)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            // Si NO hay foto, mostramos la huella dactilar por defecto
            child: rutaFoto == null
                ? const Center(child: FaIcon(FontAwesomeIcons.fingerprint, size: 60, color: lobbyGold))
                : null,
          ),
          const SizedBox(height: 50),

          // 📝 TEXTO "PÁSALE EL TELÉFONO A:" CON BORDE NEGRO
          Stack(
            alignment: Alignment.center,
            children: [
              // Borde Negro
              Text(
                "PÁSALE EL TELÉFONO A:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4.0
                    ..color = Colors.black, // Color del borde
                ),
              ),
              // Relleno Dorado
              const Text(
                "PÁSALE EL TELÉFONO A:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: lobbyGold, // Color de relleno
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 📝 NOMBRE DEL JUGADOR CON BORDE NEGRO
          Stack(
            alignment: Alignment.center,
            children: [
              // Borde Negro
              Text(
                nombreJugador.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6.0
                    ..color = Colors.black,
                ),
              ),
              // Relleno Dorado
              Text(
                nombreJugador.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                  color: lobbyGold,
                  shadows: [Shadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 8)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),

          GoldButton(text: "SOY YO", onPressed: onListo),
        ],
      ),
    );
  }
}