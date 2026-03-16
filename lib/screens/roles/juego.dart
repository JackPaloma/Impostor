import 'package:flutter/material.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../datos.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../../audio.dart';
import '../votacion/debate.dart';

import 'roles_colors.dart';
import 'roles_components.dart';

class PantallaJuego extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Map<String, int> puntajes;
  final CartaJuego carta;
  final ConfiguracionJuego config;
  final List<CartaJuego> packUsado;

  const PantallaJuego({
    super.key,
    required this.listaJugadores,
    required this.puntajes,
    required this.carta,
    required this.config,
    required this.packUsado,
  });

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> with SingleTickerProviderStateMixin {
  int turno = 0;
  bool mostrandoTransicion = true;
  double dragOffset = 0.0;
  late AnimationController _animController;
  late Animation<double> _animation;
  late List<int> indicesVivos;
  bool _sonidoEmitido = false;

  @override
  void initState() {
    super.initState();
    indicesVivos = [];
    for (int i = 0; i < widget.listaJugadores.length; i++) {
      if (widget.listaJugadores[i].estaVivo) {
        indicesVivos.add(i);
      }
    }
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = const AlwaysStoppedAnimation(0.0);
    _animController.addListener(() => setState(() => dragOffset = _animation.value));
  }

  void completarTurno() {
    if (turno < indicesVivos.length - 1) {
      setState(() {
        turno++;
        dragOffset = 0.0;
        mostrandoTransicion = true;
        _sonidoEmitido = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaDebate(
            listaJugadores: widget.listaJugadores,
            puntajes: widget.puntajes,
            carta: widget.carta,
            config: widget.config,
            packUsado: widget.packUsado,
          ),
        ),
      );
    }
  }

  void revelarTarjeta() => setState(() => mostrandoTransicion = false);

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta.dy;
      if (dragOffset > 0) dragOffset = 0;
      // AUMENTAMOS EL LÍMITE: La tarjeta ahora subirá casi por completo
      if (dragOffset < -340) dragOffset = -340;

      if (dragOffset < -150 && !_sonidoEmitido) {
        Sonidos.playTick();
        _sonidoEmitido = true;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _animation = Tween<double>(begin: dragOffset, end: 0.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int indiceReal = indicesVivos[turno];
    JugadorEnPartida jugadorActual = widget.listaJugadores[indiceReal];

    bool verPalabra = false;
    bool verCategoria = false;
    bool verPista = false;
    String textoAliados = "";

    Color colorIdentidad = jewelBlue;
    String tituloRol = "INOCENTE";
    IconData iconoRol = FontAwesomeIcons.userShield;

    if (jugadorActual.esImpostor) {
      tituloRol = "IMPOSTOR";
      colorIdentidad = jewelRed;
      iconoRol = FontAwesomeIcons.userSecret;
      verPalabra = false;
      verCategoria = false;
      verPista = widget.config.impostorTienePista;

      if (widget.config.impostoresSeConocen) {
        List<String> aliados = widget.listaJugadores
            .where((j) => j.esImpostor && j.nombre != jugadorActual.nombre)
            .map((j) => j.nombre)
            .toList();
        if (aliados.isNotEmpty) textoAliados = aliados.join(", ");
      }

    } else if (jugadorActual.esComplice) {
      tituloRol = "CÓMPLICE";
      colorIdentidad = jewelPurple;
      iconoRol = FontAwesomeIcons.masksTheater;
      verPalabra = !widget.config.modoSoloCategoria;
      verCategoria = widget.config.modoSoloCategoria;
      verPista = false;

    } else {
      tituloRol = "INOCENTE";
      colorIdentidad = jewelBlue;
      iconoRol = FontAwesomeIcons.userShield;
      verPalabra = !widget.config.modoSoloCategoria;
      verCategoria = widget.config.modoSoloCategoria;
      verPista = false;
    }

    return Scaffold(
      body: DuoFondo(
        child: SafeArea(
          child: mostrandoTransicion
              ? PantallaTransicion(
              nombreJugador: jugadorActual.nombre,
              rutaFoto: jugadorActual.rutaFoto,
              onListo: revelarTarjeta
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("TURNO DE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                const SizedBox(height: 5),
                Text(jugadorActual.nombre.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 30),

                // ÁREA DE LAS TARJETAS
                SizedBox(
                  height: 450,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [

                      // ===================================
                      // 🎴 TARJETA INFERIOR (ROL REVELADO)
                      // ===================================
                      Container(
                        width: 300,
                        height: 400,
                        decoration: BoxDecoration(
                            color: ebonyCard,
                            border: Border.all(color: colorIdentidad, width: 2),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          // ZONA SEGURA (top: 110): Empuja los elementos hacia abajo para que la tarjeta de arriba no los tape
                          padding: const EdgeInsets.only(top: 110, bottom: 20, left: 15, right: 15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (jugadorActual.estaSilenciado) ...[
                                const FaIcon(FontAwesomeIcons.microphoneSlash, size: 40, color: jewelRed),
                                const SizedBox(height: 10),
                                const Text("¡SILENCIADO!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: jewelRed)),
                                const SizedBox(height: 10),
                              ],

                              FaIcon(iconoRol, size: 50, color: colorIdentidad),
                              const SizedBox(height: 10),
                              Text(
                                  tituloRol,
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: colorIdentidad)
                              ),

                              if (jugadorActual.esComplice)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10, top: 5),
                                  child: Text("(Ayuda a los Impostores)", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),

                              if (jugadorActual.esImpostor && textoAliados.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Column(
                                    children: [
                                      const Text("TUS ALIADOS:", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text(textoAliados, textAlign: TextAlign.center, style: const TextStyle(color: jewelRed, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 15),

                              if (verPalabra)
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(12), border: Border.all(color: goldDark)),
                                    child: Text(widget.carta.palabra, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain))
                                )
                              else if (verCategoria)
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(12), border: Border.all(color: goldDark)),
                                    child: Column(
                                      children: [
                                        const Text("CATEGORÍA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                                        Text(widget.carta.categoria.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorIdentidad)),
                                      ],
                                    ))
                              else if (!jugadorActual.esImpostor && !jugadorActual.esComplice)
                                  const Text("Palabra Oculta 🔒", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),

                              if (verPista)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Column(
                                    children: [
                                      const Text("PISTA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                                      Text(widget.carta.pista, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ===================================
                      // 🔒 TARJETA SUPERIOR (LA QUE SE DESLIZA)
                      // ===================================
                      Transform.translate(
                        offset: Offset(0, dragOffset),
                        child: GestureDetector(
                          onVerticalDragUpdate: _onVerticalDragUpdate,
                          onVerticalDragEnd: _onVerticalDragEnd,
                          child: Container(
                            width: 300,
                            height: 420,
                            decoration: BoxDecoration(
                                color: ebonyCard,
                                border: Border.all(color: lobbyGoldDark, width: 2),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, -5))]
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 40),

                                // 📸 FOTO O ICONO DEL JUGADOR
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: ebonyInput,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: lobbyGoldDark, width: 3),
                                    image: jugadorActual.rutaFoto != null
                                        ? DecorationImage(
                                      image: FileImage(File(jugadorActual.rutaFoto!)),
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                  child: jugadorActual.rutaFoto == null
                                      ? const Center(child: FaIcon(FontAwesomeIcons.userSecret, size: 50, color: lobbyGold))
                                      : null,
                                ),

                                const SizedBox(height: 30),
                                const Text(
                                    "CONFIDENCIAL",
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: lobbyGold)
                                ),
                                const SizedBox(height: 15),
                                const Divider(color: goldDark, thickness: 2, indent: 40, endIndent: 40),
                                const Spacer(),
                                const FaIcon(FontAwesomeIcons.chevronUp, size: 40, color: textMuted),
                                const SizedBox(height: 5),
                                const Text("DESLIZA PARA VER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2.0, color: textMuted)),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                GoldButton(text: "LISTO", onPressed: completarTurno),
              ],
            ),
          ),
        ),
      ),
    );
  }
}