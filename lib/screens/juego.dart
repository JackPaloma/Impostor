import 'package:flutter/material.dart';
import 'dart:math';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../datos.dart';
import '../audio.dart';
import 'debate.dart';

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
      if (dragOffset < -250) dragOffset = -250;

      if (dragOffset < -125 && !_sonidoEmitido) {
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

    if (mostrandoTransicion) {
      return PantallaTransicion(nombreJugador: jugadorActual.nombre, onListo: revelarTarjeta);
    }

    // ============================================
    // 🛡️ LÓGICA DE VISIBILIDAD DE ROLES
    // ============================================
    bool verPalabra = false;
    bool verCategoria = false;
    bool verPista = false;
    String textoAliados = "";

    // Color y Título base
    Color colorIdentidad = const Color(0xFF21D4FD); // Azul Inocente
    String tituloRol = "INOCENTE";

    if (jugadorActual.esImpostor) {
      // --- IMPOSTOR ---
      tituloRol = "IMPOSTOR";
      colorIdentidad = duoRed;
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
      // --- CÓMPLICE ---
      tituloRol = "CÓMPLICE";
      colorIdentidad = const Color(0xFFB721FF); // Violeta
      // Si está el modo Solo Categoría, no ven la palabra, ven la categoría
      verPalabra = !widget.config.modoSoloCategoria;
      verCategoria = widget.config.modoSoloCategoria;
      verPista = false;

    } else {
      // --- INOCENTE NORMAL ---
      tituloRol = "INOCENTE";
      colorIdentidad = const Color(0xFF21D4FD);
      // Si está el modo Solo Categoría, no ven la palabra, ven la categoría
      verPalabra = !widget.config.modoSoloCategoria;
      verCategoria = widget.config.modoSoloCategoria;
      verPista = false;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("JUGADOR", style: duoFont(size: 20, color: duoTextSub)),
              const SizedBox(height: 10),
              Text(jugadorActual.nombre, style: duoFont(size: 40, color: duoTextMain)),
              const SizedBox(height: 40),

              SizedBox(
                height: 400,
                width: 300,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                          color: duoSurface,
                          border: Border.all(color: colorIdentidad, width: 4),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: duoBorder, offset: Offset(0, 8))]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (jugadorActual.estaSilenciado) ...[
                            const Icon(Icons.mic_off, size: 50, color: duoRed),
                            Text("¡SILENCIADO!", style: duoFont(size: 24, color: duoRed)),
                            const SizedBox(height: 10),
                          ],

                          Text(tituloRol, style: duoFont(size: 36, color: colorIdentidad)),

                          if (jugadorActual.esComplice)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text("(Ayuda a los Impostores)", style: TextStyle(color: duoTextSub, fontSize: 14)),
                            ),

                          if (jugadorActual.esImpostor && textoAliados.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Column(
                                children: [
                                  Text("TU ALIADO:", style: TextStyle(color: duoTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(textoAliados, style: TextStyle(color: duoRed, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),

                          const SizedBox(height: 15),

                          if (verPalabra)
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: duoBg, borderRadius: BorderRadius.circular(10)),
                                child: Text(widget.carta.palabra, style: duoFont(size: 24, color: duoTextMain)))
                          else if (verCategoria)
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: duoBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Text("CATEGORÍA:", style: duoFont(size: 14, color: duoTextSub)),
                                    Text(widget.carta.categoria.toUpperCase(), style: duoFont(size: 20, color: colorIdentidad)),
                                  ],
                                ))
                          else if (!jugadorActual.esImpostor && !jugadorActual.esComplice)
                              const Text("Palabra Oculta 🔒", style: TextStyle(color: duoTextSub)),

                          if (verPista)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Column(
                                children: [
                                  Text("PISTA:", style: duoFont(size: 14, color: duoTextSub)),
                                  Text(widget.carta.pista, textAlign: TextAlign.center, style: duoFont(size: 18, color: duoTextMain)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(0, dragOffset),
                      child: GestureDetector(
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        child: Container(
                          width: 300,
                          height: 380,
                          decoration: BoxDecoration(
                              color: duoSurface,
                              border: Border.all(color: duoBorder, width: 4),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: duoBorder, offset: Offset(0, 8))]),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(color: duoBg, borderRadius: BorderRadius.circular(50)),
                                  child: Icon(Icons.person, size: 60, color: AppTheme.primary)),
                              const SizedBox(height: 20),
                              Text("CONFIDENCIAL", style: duoFont(size: 24, color: duoTextMain)),
                              const SizedBox(height: 10),
                              const Divider(color: duoBorder, thickness: 3, indent: 40, endIndent: 40),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_up, size: 50, color: duoTextSub),
                              const Text("DESLIZA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: duoTextSub)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(width: 200, child: DuoButton(text: "LISTO", color: AppTheme.primary, onPressed: completarTurno)),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaTransicion extends StatelessWidget {
  final String nombreJugador;
  final VoidCallback onListo;

  const PantallaTransicion({super.key, required this.nombreJugador, required this.onListo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: duoBorder, width: 4)),
                child: const Icon(Icons.fingerprint, size: 70, color: duoTextSub)),
            const SizedBox(height: 40),
            Text("PÁSALE EL TELÉFONO A:", style: duoFont(size: 20, color: duoTextSub)),
            const SizedBox(height: 10),
            Text(nombreJugador, style: duoFont(size: 45, color: AppTheme.primary)),
            const SizedBox(height: 60),
            SizedBox(width: 200, child: DuoButton(text: "SOY YO", color: AppTheme.primary, onPressed: onListo))
          ],
        ),
      ),
    );
  }
}