import 'package:flutter/material.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../datos.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../../audio.dart';
import '../votacion/debate.dart';
import '../lobby/lobby.dart';

import 'roles_colors.dart';
import 'roles_components.dart';

class PantallaJuego extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Map<String, int> puntajes;
  final CartaJuego carta;
  final ConfiguracionJuego config;
  final List<CartaJuego> packUsado;

  final String? codigoSala;
  final List<String>? jugadoresReclamadosWeb; // 🔥 Lista de los que ya tienen celular

  const PantallaJuego({
    super.key,
    required this.listaJugadores,
    required this.puntajes,
    required this.carta,
    required this.config,
    required this.packUsado,
    this.codigoSala,
    this.jugadoresReclamadosWeb,
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

  // 🔥 Solo anotamos a los jugadores que NO tienen celular
  late List<int> indicesVivosLocales;
  bool todosLocalesListos = false;
  bool _sonidoEmitido = false;

  @override
  void initState() {
    super.initState();
    indicesVivosLocales = [];

    // Filtramos para saltarnos a los que están en la Web
    for (int i = 0; i < widget.listaJugadores.length; i++) {
      if (widget.listaJugadores[i].estaVivo) {
        bool estaReclamado = widget.jugadoresReclamadosWeb?.contains(widget.listaJugadores[i].nombre) ?? false;
        if (!estaReclamado) {
          indicesVivosLocales.add(i); // Este jugador necesita ver la pantalla del Líder
        }
      }
    }

    // Si TODOS los jugadores están en su celular web, pasamos a la pantalla de espera
    if (indicesVivosLocales.isEmpty) {
      todosLocalesListos = true;
    }

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = const AlwaysStoppedAnimation(0.0);
    _animController.addListener(() => setState(() => dragOffset = _animation.value));
  }

  void completarTurno() {
    if (turno < indicesVivosLocales.length - 1) {
      setState(() {
        turno++;
        dragOffset = 0.0;
        mostrandoTransicion = true;
        _sonidoEmitido = false;
      });
    } else {
      // Si ya todos los que no tienen celular vieron su tarjeta...
      if (widget.codigoSala != null && widget.jugadoresReclamadosWeb != null && widget.jugadoresReclamadosWeb!.isNotEmpty) {
        // ...Y hay gente en la web, mostramos la pantalla para esperar que terminen
        setState(() {
          todosLocalesListos = true;
        });
      } else {
        // ...Si jugamos solos (local), vamos al debate
        _irAlDebate();
      }
    }
  }

  void _irAlDebate() {
    // Le avisa a la Web que se acabó la espera
    if (widget.codigoSala != null) {
      FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'debate'});
    }

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

  void revelarTarjeta() => setState(() => mostrandoTransicion = false);

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta.dy;
      if (dragOffset > 0) dragOffset = 0;
      if (dragOffset < -340) dragOffset = -340;
      if (dragOffset < -150 && !_sonidoEmitido) { Sonidos.playTick(); _sonidoEmitido = true; }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _animation = Tween<double>(begin: dragOffset, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 POP SCOPE CORREGIDO PARA EVITAR CIERRES ABRUPTOS DE LA APP
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        bool? confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1510),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE3CA94), width: 2)),
            title: const Text("¿Abandonar Partida?", style: TextStyle(color: Color(0xFFE3CA94), fontWeight: FontWeight.bold)),
            content: const Text("Volverás al lobby y esta partida se cancelará.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)), onPressed: () => Navigator.pop(context, true), child: const Text("SALIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        );

        if (confirmar == true && context.mounted) {
          // Si abandona, cancela la sala web para todos
          if (widget.codigoSala != null) {
            await FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'cancelada'});
          }
          // Y vuelve al Lobby sin cerrar la app
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MenuLobby()));
        }
      },
      child: Scaffold(
        body: DuoFondo(
          child: SafeArea(
            // 🔥 PANTALLA ESPECIAL: CUANDO EL HOST YA TERMINÓ PERO ESTÁ ESPERANDO A LOS WEB
            child: todosLocalesListos
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.mobileScreen, color: jewelBlue, size: 80),
                  const SizedBox(height: 20),
                  const Text("JUGADORES WEB", style: TextStyle(color: lobbyGold, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("Esperando a que los jugadores\nen la web vean sus roles...", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)),
                  const SizedBox(height: 50),
                  // El Host presiona esto cuando todos gritan "¡Ya vi mi rol!"
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: jewelGreen, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _irAlDebate,
                    child: const Text("TODOS LISTOS -> INICIAR DEBATE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
            // PANTALLA NORMAL DE DESLIZAR TARJETAS (Solo para los que NO están en la Web)
                : Builder(
                builder: (context) {
                  int indiceReal = indicesVivosLocales[turno];
                  JugadorEnPartida jugadorActual = widget.listaJugadores[indiceReal];

                  bool verPalabra = false; bool verCategoria = false; bool verPista = false; String textoAliados = "";
                  Color colorIdentidad = jewelBlue; String tituloRol = "INOCENTE"; IconData iconoRol = FontAwesomeIcons.userShield;

                  bool todosVenCategoria = widget.config.mostrarCategoria == VisibilidadCategoria.todos;
                  bool soloInocentesVenCategoria = widget.config.mostrarCategoria == VisibilidadCategoria.soloInocentes;
                  bool soloImpostorVeCategoria = widget.config.mostrarCategoria == VisibilidadCategoria.soloImpostor;

                  if (jugadorActual.esImpostor) {
                    tituloRol = "IMPOSTOR"; colorIdentidad = jewelRed; iconoRol = FontAwesomeIcons.userSecret;
                    verPalabra = false; verCategoria = todosVenCategoria || soloImpostorVeCategoria; verPista = widget.config.impostorTienePista;
                    if (widget.config.impostoresSeConocen) {
                      List<String> aliados = widget.listaJugadores.where((j) => j.esImpostor && j.nombre != jugadorActual.nombre).map((j) => j.nombre).toList();
                      if (aliados.isNotEmpty) textoAliados = aliados.join(", ");
                    }
                  } else if (jugadorActual.esComplice) {
                    tituloRol = "CÓMPLICE"; colorIdentidad = jewelPurple; iconoRol = FontAwesomeIcons.masksTheater;
                    verPalabra = true; verCategoria = todosVenCategoria; verPista = false;
                  } else {
                    tituloRol = "INOCENTE"; colorIdentidad = jewelBlue; iconoRol = FontAwesomeIcons.userShield;
                    verPalabra = true; verCategoria = todosVenCategoria || soloInocentesVenCategoria; verPista = false;
                  }

                  return mostrandoTransicion
                      ? PantallaTransicion(nombreJugador: jugadorActual.nombre, rutaFoto: jugadorActual.rutaFoto, onListo: revelarTarjeta)
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("TURNO DE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                        const SizedBox(height: 5),
                        Text(jugadorActual.nombre.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textMain)),
                        const SizedBox(height: 30),

                        SizedBox(
                          height: 450, width: 300,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 300, height: 400,
                                decoration: BoxDecoration(color: ebonyCard, border: Border.all(color: colorIdentidad, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(top: 110, bottom: 20, left: 15, right: 15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (jugadorActual.estaSilenciado) ...[const FaIcon(FontAwesomeIcons.microphoneSlash, size: 40, color: jewelRed), const SizedBox(height: 10), const Text("¡SILENCIADO!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: jewelRed)), const SizedBox(height: 10)],
                                      FaIcon(iconoRol, size: 50, color: colorIdentidad), const SizedBox(height: 10),
                                      Text(tituloRol, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: colorIdentidad)),
                                      if (jugadorActual.esComplice) const Padding(padding: EdgeInsets.only(bottom: 10, top: 5), child: Text("(Ayuda a los Impostores)", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold))),
                                      if (jugadorActual.esImpostor && textoAliados.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10.0), child: Column(children: [const Text("TUS ALIADOS:", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)), Text(textoAliados, textAlign: TextAlign.center, style: const TextStyle(color: jewelRed, fontSize: 18, fontWeight: FontWeight.bold))])),
                                      const SizedBox(height: 15),
                                      if (verPalabra) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(12), border: Border.all(color: goldDark)), child: Text(widget.carta.palabra, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain)))
                                      else if (!jugadorActual.esImpostor && !jugadorActual.esComplice) const Padding(padding: EdgeInsets.only(bottom: 10.0), child: Text("Palabra Oculta 🔒", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                      if (verCategoria && widget.carta.categoria.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(12), border: Border.all(color: goldDark)), child: Column(children: [const Text("CATEGORÍA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text(widget.carta.categoria.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorIdentidad))])),
                                      if (verPista) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(children: [const Text("PISTA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text(widget.carta.pista, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain))])),
                                    ],
                                  ),
                                ),
                              ),

                              Transform.translate(
                                offset: Offset(0, dragOffset),
                                child: GestureDetector(
                                  onVerticalDragUpdate: _onVerticalDragUpdate,
                                  onVerticalDragEnd: _onVerticalDragEnd,
                                  child: Container(
                                    width: 300, height: 420,
                                    decoration: BoxDecoration(color: ebonyCard, border: Border.all(color: lobbyGoldDark, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, -5))]),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 40),
                                        Container(height: 110, width: 110, decoration: BoxDecoration(color: ebonyInput, shape: BoxShape.circle, border: Border.all(color: lobbyGoldDark, width: 3), image: jugadorActual.rutaFoto != null ? DecorationImage(image: FileImage(File(jugadorActual.rutaFoto!)), fit: BoxFit.cover) : null), child: jugadorActual.rutaFoto == null ? const Center(child: FaIcon(FontAwesomeIcons.userSecret, size: 50, color: lobbyGold)) : null),
                                        const SizedBox(height: 30),
                                        const Text("CONFIDENCIAL", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: lobbyGold)),
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
                  );
                }
            ),
          ),
        ),
      ),
    );
  }
}