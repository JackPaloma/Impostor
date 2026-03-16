import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models.dart';
import '../../audio.dart';
import 'votacion_colors.dart';

// 1. BOTÓN DORADO ESTÁNDAR
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? colorOverride;
  final Color? textColorOverride;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.colorOverride,
    this.textColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        decoration: BoxDecoration(
          color: colorOverride ?? lobbyGold,
          borderRadius: BorderRadius.circular(20),
          border: colorOverride != null ? Border.all(color: lobbyGoldDark, width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              FaIcon(icon, color: textColorOverride ?? const Color(0xFF2A1B0E), size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textColorOverride ?? const Color(0xFF2A1B0E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. ITEM DE PUNTAJE EN PANTALLA DE RESULTADOS
class ScoreItemAnimado extends StatelessWidget {
  final String nombre;
  final bool esImpostor;
  final bool esComplice;
  final bool estaVivo;
  final int puntajeFinal;
  final int ganancia;
  final bool fueCastigado;

  const ScoreItemAnimado({
    super.key,
    required this.nombre,
    required this.esImpostor,
    this.esComplice = false,
    required this.estaVivo,
    required this.puntajeFinal,
    required this.ganancia,
    required this.fueCastigado,
  });

  @override
  Widget build(BuildContext context) {
    IconData icono = FontAwesomeIcons.userShield;
    Color colorRol = lobbyGold;

    if (esImpostor) {
      icono = FontAwesomeIcons.userSecret;
      colorRol = jewelRed;
    } else if (esComplice) {
      icono = FontAwesomeIcons.masksTheater;
      colorRol = jewelPurple;
    }

    Color colorIconoFinal = estaVivo ? colorRol : textMuted;
    Color colorTextoNombre = estaVivo ? colorRol : textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: goldDark)),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
                children: [
                  FaIcon(icono, color: colorIconoFinal, size: 24),
                  const SizedBox(width: 15),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            nombre.toUpperCase(),
                            style: TextStyle(
                                color: colorTextoNombre,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.0,
                                decoration: !estaVivo ? TextDecoration.lineThrough : null
                            )
                        ),
                        if (!estaVivo) const Text("ELIMINADO", style: TextStyle(color: jewelRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ]
                  ),
                ]
            ),
            Row(
                children: [
                  Text("$puntajeFinal pts", style: const TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (ganancia > 0) Text(" +$ganancia", style: const TextStyle(color: jewelGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (fueCastigado) const Text(" -1", style: TextStyle(color: jewelRed, fontWeight: FontWeight.bold, fontSize: 16)),
                ]
            ),
          ]
      ),
    );
  }
}

// 3. DIÁLOGO DE EXPULSIÓN ANIMADO PREMIUM
class DialogoExpulsionAnimado extends StatefulWidget {
  final JugadorEnPartida jugador;
  const DialogoExpulsionAnimado({super.key, required this.jugador});
  @override
  State<DialogoExpulsionAnimado> createState() => _DialogoExpulsionAnimadoState();
}

class _DialogoExpulsionAnimadoState extends State<DialogoExpulsionAnimado> with TickerProviderStateMixin {
  late AnimationController _fallController;
  late Animation<double> _textFall;
  late Animation<double> _iconFall;
  late Animation<Color?> _colorFade;
  late AnimationController _fireController;
  late Animation<Color?> _fireAnimation;

  @override
  void initState() {
    super.initState();
    Sonidos.playReveal();
    _fallController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _textFall = Tween<double>(begin: 0, end: 800).animate(CurvedAnimation(parent: _fallController, curve: const Interval(0.2, 1.0, curve: Curves.easeInExpo)));
    _iconFall = Tween<double>(begin: 0, end: 800).animate(CurvedAnimation(parent: _fallController, curve: const Interval(0.3, 1.0, curve: Curves.easeInExpo)));
    _colorFade = ColorTween(begin: lobbyGold, end: textMuted).animate(_fallController);

    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fireAnimation = ColorTween(begin: jewelRed, end: Colors.orange).animate(_fireController);

    if (!widget.jugador.esImpostor) {
      _fallController.forward();
    } else {
      _fireController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fallController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ebonyInput, // Fondo oscuro profundo
      body: AnimatedBuilder(
        animation: Listenable.merge([_fallController, _fireController]),
        builder: (context, child) {
          if (widget.jugador.esImpostor) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.jugador.nombre.toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 2.0)),
                const SizedBox(height: 20),
                Text("ERA UN IMPOSTOR", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: _fireAnimation.value!)),
                const SizedBox(height: 50),
                FaIcon(FontAwesomeIcons.fire, size: 100, color: _fireAnimation.value!)
              ]),
            );
          }
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Transform.translate(offset: Offset(0, _textFall.value), child: Column(children: [
                Text(widget.jugador.nombre.toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 2.0)),
                const SizedBox(height: 20),
                Text("NO ERA IMPOSTOR", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: _colorFade.value!)),
              ])),
              const SizedBox(height: 50),
              Transform.translate(offset: Offset(0, _iconFall.value), child: FaIcon(FontAwesomeIcons.userLargeSlash, size: 100, color: _colorFade.value!)),
            ]),
          );
        },
      ),
    );
  }
}