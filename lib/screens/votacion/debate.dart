import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import '../../models.dart';
import '../../widgets.dart';
import '../../audio.dart';
import '../../datos.dart';
import '../roles/juego.dart';
import '../lobby/lobby.dart';

import 'votacion_colors.dart';
import 'votacion_components.dart';
import 'votacion.dart';

class PantallaDebate extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Map<String, int> puntajes;
  final CartaJuego carta;
  final ConfiguracionJuego config;
  final List<CartaJuego> packUsado;

  const PantallaDebate({
    super.key,
    required this.listaJugadores,
    required this.puntajes,
    required this.carta,
    required this.config,
    required this.packUsado,
  });

  @override
  State<PantallaDebate> createState() => _PantallaDebateState();
}

class _PantallaDebateState extends State<PantallaDebate> {
  Timer? _timer;
  int _segundosRestantes = 0;
  int _segundosTranscurridos = 0;
  bool _mostrarResultadosFinales = false;
  String ganadorMensaje = "";
  Color colorGanador = Colors.white;
  bool ganaronInocentes = true;

  bool _puntoQuitado = false;
  String? _jugadorCastigado;

  @override
  void initState() {
    super.initState();

    if (widget.config.modoContraReloj) {
      _segundosRestantes = widget.config.minutosReloj * 60;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (widget.config.modoContraReloj) {
          _segundosRestantes--;
          if (_segundosRestantes <= 0) terminarJuego(false);
        } else {
          _segundosTranscurridos++;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ejecutarRolesEspeciales();
    });
  }

  void _ejecutarRolesEspeciales() async {
    final vivos = widget.listaJugadores.where((j) => j.estaVivo).toList();

    // 0. ANUNCIO DE TURNO INICIAL
    if (vivos.isNotEmpty) {
      final jugadorInicial = vivos[Random().nextInt(vivos.length)];
      final bool esHorario = Random().nextBool();
      final String direccionText = esHorario ? "HORARIO" : "ANTIHORARIO";
      final IconData direccionIcon = esHorario ? FontAwesomeIcons.arrowRotateRight : FontAwesomeIcons.arrowRotateLeft;

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ebonyCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
          title: const FaIcon(FontAwesomeIcons.bullhorn, color: lobbyGold, size: 50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("ORDEN DE DEBATE", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              const Text("EMPIEZA A HABLAR:", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(jugadorInicial.nombre.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: lobbyGold)),
              const SizedBox(height: 20),
              const Text("SENTIDO:", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(direccionIcon, color: textMain, size: 24),
                  const SizedBox(width: 10),
                  Text(direccionText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textMain)),
                ],
              ),
            ],
          ),
          actions: [
            Center(child: SizedBox(width: 200, child: GoldButton(text: "¡A DEBATIR!", onPressed: () => Navigator.pop(context))))
          ],
        ),
      );
    }

    // 1. ROL: EL SILENCIOSO
    if (widget.config.rolSilencioso) {
      if (vivos.isNotEmpty) {
        final victima = vivos[Random().nextInt(vivos.length)];
        setState(() => victima.estaSilenciado = true);

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: ebonyCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelRed, width: 2)),
            title: const FaIcon(FontAwesomeIcons.microphoneSlash, color: jewelRed, size: 50),
            content: Text("EL SILENCIOSO HA ACTUADO\n\n${victima.nombre.toUpperCase()} NO PUEDE HABLAR ESTE TURNO.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
            actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "OK", onPressed: () => Navigator.pop(context))))],
          ),
        );
      }
    }

    // 2. ROL: DETECTIVE
    if (widget.config.rolDetective) {
      if (vivos.isNotEmpty) {
        final detective = vivos[Random().nextInt(vivos.length)];
        setState(() => detective.esDetective = true);

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: ebonyCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelBlue, width: 2)),
            title: const FaIcon(FontAwesomeIcons.magnifyingGlass, color: jewelBlue, size: 50),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("¡NUEVO DETECTIVE!", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 10),
                Text(detective.nombre.toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: jewelBlue)),
                const SizedBox(height: 20),
                const Text("Debe hacer una pregunta indirecta a un jugador de su elección.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)),
              ],
            ),
            actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "ENTENDIDO", onPressed: () => Navigator.pop(context))))],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formatoTiempo {
    int s = widget.config.modoContraReloj ? _segundosRestantes : _segundosTranscurridos;
    int minutos = s ~/ 60;
    int segs = s % 60;
    return "${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}";
  }

  Future<void> _guardarPuntajesEnDisco() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('puntajes', jsonEncode(widget.puntajes));
  }

  void abrirDialogoCastigo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ebonyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelRed, width: 2)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FaIcon(FontAwesomeIcons.bolt, color: jewelRed),
            SizedBox(width: 10),
            Text("CASTIGAR A...", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: jewelRed)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: widget.listaJugadores.length,
            itemBuilder: (context, index) {
              final jugador = widget.listaJugadores[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GoldButton(
                  text: "${jugador.nombre.toUpperCase()} (${widget.puntajes[jugador.nombre]})",
                  colorOverride: ebonyInput,
                  textColorOverride: textMain,
                  onPressed: () {
                    setState(() {
                      widget.puntajes[jugador.nombre] = (widget.puntajes[jugador.nombre] ?? 0) - 1;
                      _puntoQuitado = true;
                      _jugadorCastigado = jugador.nombre;
                    });
                    _guardarPuntajesEnDisco();
                    Navigator.pop(context);
                    Sonidos.playReveal();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          Center(child: SizedBox(width: 200, child: GoldButton(text: "CANCELAR", colorOverride: ebonyInput, textColorOverride: textMuted, onPressed: () => Navigator.pop(context))))
        ],
      ),
    );
  }

  void abrirVotacion() {
    if (widget.config.modoVotacionAnonima) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaVotacionTurnos(
        listaJugadores: widget.listaJugadores,
        onTerminarVotacion: (nombre) {
          if (nombre != null) {
            ejecutarExpulsion(widget.listaJugadores.firstWhere((j) => j.nombre == nombre));
          } else {
            ejecutarEventosRonda();
          }
        },
      )));
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ebonyCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
          title: const Text("¿A QUIÉN EXPULSAMOS?", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: widget.listaJugadores.where((j) => j.estaVivo).map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GoldButton(
                    text: j.nombre.toUpperCase(),
                    colorOverride: ebonyInput,
                    textColorOverride: textMain,
                    onPressed: () {
                      Navigator.pop(context);
                      ejecutarExpulsion(j);
                    }
                ),
              )).toList(),
            ),
          ),
          actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "SALTAR", colorOverride: ebonyInput, textColorOverride: textMuted, onPressed: () => Navigator.pop(context))))],
        ),
      );
    }
  }

  void ejecutarExpulsion(JugadorEnPartida jugador) {
    setState(() {
      jugador.estaVivo = false;
      if (widget.config.muerteSincronizada && jugador.esImpostor) {
        for (var j in widget.listaJugadores) {
          if (j.esImpostor) j.estaVivo = false;
        }
      }
    });

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(seconds: 4), () {
            if (context.mounted) Navigator.pop(context);
          });
          return DialogoExpulsionAnimado(jugador: jugador);
        }
    ).then((_) {
      if (!verificarVictoria()) ejecutarEventosRonda();
    });
  }

  bool verificarVictoria() {
    int impostores = widget.listaJugadores.where((j) => j.esImpostor && j.estaVivo).length;
    int inocentes = widget.listaJugadores.where((j) => !j.esImpostor && j.estaVivo).length;

    if (impostores == 0) { terminarJuego(true); return true; }
    if (impostores >= inocentes) { terminarJuego(false); return true; }

    return false;
  }

  void terminarJuego(bool gananInocentes) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      this.ganaronInocentes = gananInocentes;
      ganadorMensaje = gananInocentes ? "¡VICTORIA INOCENTE!" : "¡VICTORIA IMPOSTOR!";
      colorGanador = gananInocentes ? jewelBlue : jewelRed;
      _mostrarResultadosFinales = true;

      for (var j in widget.listaJugadores) {
        int puntosGanados = 0;
        if (j.esComplice) {
          if (!gananInocentes) puntosGanados = 2;
        } else if (j.esImpostor) {
          if (!gananInocentes) puntosGanados = 3;
        } else {
          if (gananInocentes) puntosGanados = 1;
        }
        if (puntosGanados > 0) {
          widget.puntajes[j.nombre] = (widget.puntajes[j.nombre] ?? 0) + puntosGanados;
        }
      }
    });
    _guardarPuntajesEnDisco();
  }

  void ejecutarEventosRonda() async {
    if (widget.config.modoCaos) {
      final nuevaCarta = widget.packUsado[Random().nextInt(widget.packUsado.length)];
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ebonyCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelPurple, width: 2)),
          title: const FaIcon(FontAwesomeIcons.shuffle, color: jewelPurple, size: 50),
          content: const Text("¡MODO CAOS!\n\nLA PALABRA HA CAMBIADO PARA ESTA RONDA.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
          actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "ENTENDIDO", onPressed: () => Navigator.pop(context))))],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaJuego(listaJugadores: widget.listaJugadores, puntajes: widget.puntajes, carta: nuevaCarta, config: widget.config, packUsado: widget.packUsado)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrarResultadosFinales) {
      // --- FASE DE DEBATE (Pantalla del Temporizador) ---
      int vivos = widget.listaJugadores.where((j) => j.estaVivo).length;
      return Scaffold(
        backgroundColor: const Color(0xFF150A0A), // Fondo rojizo muy oscuro
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: jewelRed, width: 4), color: ebonyInput),
                child: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 70, color: jewelRed),
              ),
              const SizedBox(height: 30),
              Text(widget.config.modoContraReloj ? "TIEMPO RESTANTE" : "ENCUENTREN AL\nIMPOSTOR", textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 2.0)),
              const SizedBox(height: 15),
              Text(formatoTiempo, style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: jewelRed, fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 10),
              Text("$vivos JUGADORES VIVOS", style: const TextStyle(color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 60),
              SizedBox(width: 220, child: GoldButton(text: "VOTAR", onPressed: abrirVotacion)),
            ],
          ),
        ),
      );
    }

    // --- FASE DE RESULTADOS FINALES ---
    return Scaffold(
      body: DuoFondo(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(ganadorMensaje, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorGanador, letterSpacing: 2.0)),
                const SizedBox(height: 10),
                Text("TIEMPO: $formatoTiempo", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                const SizedBox(height: 30),

                // TARJETA DE PALABRA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(color: ebonyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: lobbyGoldDark, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 10)]),
                  child: Column(children: [
                    Text(widget.config.modoCaos ? "ÚLTIMA PALABRA:" : "LA PALABRA ERA:", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.5)),
                    const SizedBox(height: 5),
                    Text(widget.carta.palabra.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: lobbyGold, letterSpacing: 1.0))
                  ]),
                ),

                const SizedBox(height: 20),

                // LISTA DE PUNTAJES
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: ebonyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: goldDark, width: 1.5)),
                    child: ListView.builder(
                      itemCount: widget.listaJugadores.length,
                      itemBuilder: (context, index) {
                        final jugador = widget.listaJugadores[index];
                        int pts = widget.puntajes[jugador.nombre] ?? 0;

                        int ganancia = 0;
                        if (jugador.esComplice) {
                          ganancia = (!ganaronInocentes) ? 2 : 0;
                        } else if (jugador.esImpostor) {
                          ganancia = (!ganaronInocentes) ? 3 : 0;
                        } else {
                          ganancia = (ganaronInocentes) ? 1 : 0;
                        }

                        bool fueCastigado = (jugador.nombre == _jugadorCastigado);

                        return ScoreItemAnimado(
                            nombre: jugador.nombre,
                            esImpostor: jugador.esImpostor,
                            esComplice: jugador.esComplice,
                            estaVivo: jugador.estaVivo,
                            puntajeFinal: pts,
                            ganancia: ganancia,
                            fueCastigado: fueCastigado
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BOTONES FINALES
                Row(
                  children: [
                    if (!_puntoQuitado) ...[
                      Expanded(
                        flex: 1,
                        child: GoldButton(
                            text: "", // Texto vacío porque usamos icono
                            icon: FontAwesomeIcons.bolt,
                            colorOverride: ebonyInput,
                            textColorOverride: jewelRed,
                            onPressed: abrirDialogoCastigo
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 3,
                      child: GoldButton(
                          text: "JUGAR OTRA VEZ",
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => MenuLobby(puntajesGuardados: widget.puntajes, configGuardada: widget.config)),
                                    (r) => false
                            );
                          }
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}