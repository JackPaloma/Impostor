import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../audio.dart';
import '../datos.dart';
import 'juego.dart';
import 'lobby.dart';
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

  // Variables para el control del castigo
  bool _puntoQuitado = false;
  String? _jugadorCastigado;

  @override
  void initState() {
    super.initState();

    // Configuración del Temporizador
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

    // EJECUTAR EVENTOS DE ROLES ESPECIALES AL INICIO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ejecutarRolesEspeciales();
    });
  }

  void _ejecutarRolesEspeciales() async {
    final vivos = widget.listaJugadores.where((j) => j.estaVivo).toList();

    // 0. ANUNCIO DE TURNO INICIAL Y SENTIDO
    if (vivos.isNotEmpty) {
      final jugadorInicial = vivos[Random().nextInt(vivos.length)];
      final bool esHorario = Random().nextBool();
      final String direccionText = esHorario ? "HORARIO" : "ANTIHORARIO";
      final IconData direccionIcon = esHorario ? Icons.rotate_right : Icons.rotate_left;

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: duoSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.record_voice_over, color: AppTheme.primary, size: 50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("ORDEN DE DEBATE", textAlign: TextAlign.center, style: duoFont(size: 24, color: duoTextMain)),
              const SizedBox(height: 20),
              const Text("EMPIEZA A HABLAR:", style: TextStyle(color: duoTextSub, fontSize: 14)),
              Text(jugadorInicial.nombre, style: duoFont(size: 32, color: AppTheme.primary)),
              const SizedBox(height: 20),
              const Text("SENTIDO:", style: TextStyle(color: duoTextSub, fontSize: 14)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(direccionIcon, color: duoYellow, size: 30),
                  const SizedBox(width: 10),
                  Text(direccionText, style: duoFont(size: 24, color: duoYellow)),
                ],
              ),
            ],
          ),
          actions: [
            Center(
                child: SizedBox(
                    width: 150,
                    child: DuoButton(text: "¡A DEBATIR!", color: AppTheme.primary, onPressed: () => Navigator.pop(context))
                )
            )
          ],
        ),
      );
    }

    // 1. ROL: EL SILENCIOSO (Silencia a alguien al azar)
    if (widget.config.rolSilencioso) {
      if (vivos.isNotEmpty) {
        final victima = vivos[Random().nextInt(vivos.length)];
        setState(() => victima.estaSilenciado = true);

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: duoSurface,
            title: const Icon(Icons.mic_off, color: duoRed, size: 50),
            content: Text("EL SILENCIOSO HA ACTUADO\n\n${victima.nombre} NO PUEDE HABLAR.", textAlign: TextAlign.center, style: duoFont(size: 20)),
            actions: [DuoButton(text: "OK", color: AppTheme.primary, onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }

    // 2. ROL: DETECTIVE (Se revela y recibe instrucción)
    if (widget.config.rolDetective) {
      if (vivos.isNotEmpty) {
        // Elegimos un detective al azar entre los vivos
        final detective = vivos[Random().nextInt(vivos.length)];
        setState(() => detective.esDetective = true);

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: duoSurface,
            title: const Icon(Icons.search, color: Color(0xFF21D4FD), size: 50),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("¡NUEVO DETECTIVE!", textAlign: TextAlign.center, style: duoFont(size: 22, color: duoTextMain)),
                const SizedBox(height: 10),
                Text(detective.nombre, style: duoFont(size: 30, color: const Color(0xFF21D4FD))),
                const SizedBox(height: 20),
                const Text("Debe hacer una pregunta indirecta a un jugador de su elección.", textAlign: TextAlign.center, style: TextStyle(color: duoTextSub, fontSize: 16)),
              ],
            ),
            actions: [DuoButton(text: "ENTENDIDO", color: AppTheme.primary, onPressed: () => Navigator.pop(context))],
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

  // --- LÓGICA DE CASTIGO (-1 Punto) ---
  void abrirDialogoCastigo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: duoSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: duoRed),
            const SizedBox(width: 10),
            Text("CASTIGAR A...", textAlign: TextAlign.center, style: duoFont(size: 20, color: duoRed)),
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
                child: DuoButton(
                  text: "${jugador.nombre} (${widget.puntajes[jugador.nombre]})",
                  color: duoSurface,
                  shadowColor: duoBorder,
                  onPressed: () {
                    setState(() {
                      widget.puntajes[jugador.nombre] = (widget.puntajes[jugador.nombre] ?? 0) - 1;
                      _puntoQuitado = true;
                      _jugadorCastigado = jugador.nombre;
                    });
                    _guardarPuntajesEnDisco();
                    Navigator.pop(context);
                    Sonidos.playReveal(); // Sonido de impacto
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          DuoButton(text: "CANCELAR", color: duoBlue, onPressed: () => Navigator.pop(context))
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
          backgroundColor: duoSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("¿A QUIÉN EXPULSAMOS?", textAlign: TextAlign.center, style: duoFont(size: 22, color: duoTextMain)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: widget.listaJugadores.where((j) => j.estaVivo).map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DuoButton(text: j.nombre, color: duoSurface, shadowColor: duoBorder, onPressed: () {
                  Navigator.pop(context);
                  ejecutarExpulsion(j);
                }),
              )).toList(),
            ),
          ),
          actions: [Center(child: SizedBox(width: 200, child: DuoButton(text: "SALTAR (NADIE)", color: duoSurface, shadowColor: duoBorder, onPressed: () => Navigator.pop(context))))],
        ),
      );
    }
  }

  void ejecutarExpulsion(JugadorEnPartida jugador) {
    setState(() {
      jugador.estaVivo = false;
      // Regla: Sincronía Vital
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

    // Si mueren todos los impostores -> Ganan Inocentes
    if (impostores == 0) { terminarJuego(true); return true; }
    // Si hay igual o más impostores que inocentes -> Ganan Impostores
    if (impostores >= inocentes) { terminarJuego(false); return true; }

    return false;
  }

  void terminarJuego(bool gananInocentes) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      this.ganaronInocentes = gananInocentes;
      ganadorMensaje = gananInocentes ? "¡GANAN LOS INOCENTES!" : "¡GANA EL IMPOSTOR!";
      colorGanador = gananInocentes ? AppTheme.primary : duoRed;
      _mostrarResultadosFinales = true;

      // CÁLCULO DE PUNTAJES CON CÓMPLICE
      for (var j in widget.listaJugadores) {
        int puntosGanados = 0;

        if (j.esComplice) {
          // El Cómplice gana 2 puntos si ganan los impostores
          if (!gananInocentes) puntosGanados = 2;
        } else if (j.esImpostor) {
          // Impostor gana 3 puntos si gana
          if (!gananInocentes) puntosGanados = 3;
        } else {
          // Inocente gana 1 punto si gana
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
    // Evento CAOS (Cambio de palabra)
    if (widget.config.modoCaos) {
      final nuevaCarta = widget.packUsado[Random().nextInt(widget.packUsado.length)];
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: duoSurface,
          title: const Icon(Icons.shuffle, color: duoYellow, size: 50),
          content: Text("¡MODO CAOS!\n\nLA PALABRA CAMBIÓ.", textAlign: TextAlign.center, style: duoFont(size: 20)),
          actions: [DuoButton(text: "ENTENDIDO", color: duoBlue, onPressed: () => Navigator.pop(context))],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaJuego(listaJugadores: widget.listaJugadores, puntajes: widget.puntajes, carta: nuevaCarta, config: widget.config, packUsado: widget.packUsado)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrarResultadosFinales) {
      // --- FASE DE DEBATE ---
      int vivos = widget.listaJugadores.where((j) => j.estaVivo).length;
      return Scaffold(
        backgroundColor: duoRed,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5), color: const Color(0xFFEA2B2B)),
                child: const Icon(Icons.search, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Text(widget.config.modoContraReloj ? "TIEMPO RESTANTE" : "ENCUENTREN AL\nIMPOSTOR", textAlign: TextAlign.center, style: duoFont(size: 35, color: Colors.white)),
              const SizedBox(height: 10),
              Text(formatoTiempo, style: duoFont(size: 60, color: Colors.white)),
              const SizedBox(height: 10),
              Text("$vivos jugadores vivos", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 50),
              SizedBox(width: 200, child: DuoButton(text: "VOTAR", color: duoSurface, shadowColor: duoBorder, onPressed: abrirVotacion)),
            ],
          ),
        ),
      );
    }

    // --- FASE DE RESULTADOS ---
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(ganadorMensaje, textAlign: TextAlign.center, style: duoFont(size: 30, color: colorGanador)),
              const SizedBox(height: 10),
              Text("Tiempo: $formatoTiempo", style: duoFont(size: 20, color: duoTextSub)),
              const SizedBox(height: 20),

              // TARJETA DE PALABRA
              Container(
                width: double.infinity, padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: duoSurface, borderRadius: BorderRadius.circular(15), border: Border.all(color: duoBorder, width: 2)),
                child: Column(children: [
                  Text(widget.config.modoCaos ? "ÚLTIMA PALABRA:" : "LA PALABRA ERA:", style: duoFont(size: 16, color: duoTextSub)),
                  Text(widget.carta.palabra, style: duoFont(size: 35, color: AppTheme.primary))
                ]),
              ),

              const SizedBox(height: 20),

              // LISTA DE PUNTAJES
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: duoSurface, borderRadius: BorderRadius.circular(15), border: Border.all(color: duoBorder, width: 2)),
                  child: ListView.builder(
                    itemCount: widget.listaJugadores.length,
                    itemBuilder: (context, index) {
                      final jugador = widget.listaJugadores[index];
                      int pts = widget.puntajes[jugador.nombre] ?? 0;

                      // Cálculo visual de ganancia para mostrar en verde
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
                          esComplice: jugador.esComplice, // <-- Cómplice
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

              // BOTONES DE ACCIÓN
              Row(
                children: [
                  // BOTÓN CASTIGO (Rayo)
                  if (!_puntoQuitado) ...[
                    Expanded(
                      child: DuoButton(
                          icon: Icons.bolt, // Icono de rayo
                          color: duoRed,
                          onPressed: abrirDialogoCastigo
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // BOTÓN JUGAR OTRA VEZ
                  Expanded(
                    flex: 2,
                    child: DuoButton(
                        text: "JUGAR OTRA VEZ",
                        color: AppTheme.primary,
                        onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MenuLobby(puntajesGuardados: widget.puntajes, configGuardada: widget.config)), (r) => false)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DE ITEM DE PUNTAJE (Con soporte para Cómplice y Castigo) ---
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
    IconData icono = Icons.person;
    Color colorRol = AppTheme.primary;
    const Color colorComplice = Color(0xFFB721FF); // Violeta

    if (esImpostor) {
      icono = Icons.whatshot;
      colorRol = duoRed;
    } else if (esComplice) {
      icono = Icons.theater_comedy;
      colorRol = colorComplice;
    }

    Color colorIconoFinal = estaVivo ? colorRol : duoTextSub;

    Color colorTextoNombre;
    if (!estaVivo) {
      colorTextoNombre = duoTextSub;
    } else if (esImpostor) {
      colorTextoNombre = duoRed;
    } else if (esComplice) {
      colorTextoNombre = colorComplice;
    } else {
      colorTextoNombre = duoTextMain;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: duoBorder))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icono, color: colorIconoFinal),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: TextStyle(color: colorTextoNombre, fontWeight: FontWeight.bold, fontSize: 18, decoration: !estaVivo ? TextDecoration.lineThrough : null)),
            if (!estaVivo) const Text("Eliminado", style: TextStyle(color: duoRed, fontSize: 12)),
          ]),
        ]),
        Row(children: [
          Text("$puntajeFinal pts", style: const TextStyle(color: duoTextMain, fontWeight: FontWeight.bold, fontSize: 18)),
          if (ganancia > 0) Text(" +$ganancia", style: const TextStyle(color: duoYellow, fontWeight: FontWeight.bold)),
          if (fueCastigado) const Text(" -1", style: TextStyle(color: duoRed, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ]),
    );
  }
}

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
    _colorFade = ColorTween(begin: AppTheme.primary, end: duoBorder).animate(_fallController);

    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fireAnimation = ColorTween(begin: duoRed, end: duoYellow).animate(_fireController);

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
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fallController, _fireController]),
        builder: (context, child) {
          if (widget.jugador.esImpostor) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.jugador.nombre, style: duoFont(size: 40, color: Colors.white)),
                const SizedBox(height: 20),
                Text("Era un Impostor.", style: duoFont(size: 30, color: _fireAnimation.value!)),
                const SizedBox(height: 50),
                Icon(Icons.whatshot, size: 100, color: _fireAnimation.value!)
              ]),
            );
          }
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Transform.translate(offset: Offset(0, _textFall.value), child: Column(children: [
                Text(widget.jugador.nombre, style: duoFont(size: 40, color: Colors.white)),
                const SizedBox(height: 20),
                Text("No era un Impostor.", style: duoFont(size: 30, color: _colorFade.value!)),
              ])),
              const SizedBox(height: 50),
              Transform.translate(offset: Offset(0, _iconFall.value), child: Icon(Icons.person_off, size: 100, color: _colorFade.value!)),
            ]),
          );
        },
      ),
    );
  }
}