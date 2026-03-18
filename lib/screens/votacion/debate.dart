import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

import '../../models.dart';
import '../../widgets.dart';
import '../../audio.dart';
import '../../datos.dart';
import '../roles/juego.dart';
import '../lobby/lobby.dart';

import 'votacion_colors.dart';
import 'votacion_components.dart';
import 'votacion.dart'; // 🔥 AQUÍ ESTÁ LA IMPORTACIÓN CRÍTICA

class PantallaDebate extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Map<String, int> puntajes;
  final CartaJuego carta;
  final ConfiguracionJuego config;
  final List<CartaJuego> packUsado;
  final String? codigoSala;
  final List<String>? jugadoresReclamadosWeb;

  const PantallaDebate({
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

  bool _procesandoVotos = false;

  @override
  void initState() {
    super.initState();

    if (widget.codigoSala != null) {
      List<String> vivosNombres = widget.listaJugadores.where((j) => j.estaVivo).map((j) => j.nombre).toList();
      FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/vivos').set(vivosNombres);
    }

    if (widget.config.modoContraReloj) {
      _segundosRestantes = widget.config.minutosReloj * 60;
      if (widget.codigoSala != null) {
        int tiempoFinMs = DateTime.now().millisecondsSinceEpoch + (_segundosRestantes * 1000);
        FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'tiempoFin': tiempoFinMs});
      }
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

    WidgetsBinding.instance.addPostFrameCallback((_) { _ejecutarRolesEspeciales(); });
  }

  void _ejecutarRolesEspeciales() async {
    final vivos = widget.listaJugadores.where((j) => j.estaVivo).toList();
    if (vivos.isNotEmpty) {
      final jugadorInicial = vivos[Random().nextInt(vivos.length)];
      final bool esHorario = Random().nextBool();
      final String dirText = esHorario ? "HORARIO" : "ANTIHORARIO";
      final IconData dirIcon = esHorario ? FontAwesomeIcons.arrowRotateRight : FontAwesomeIcons.arrowRotateLeft;

      if (widget.codigoSala != null) FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'primerJugador': jugadorInicial.nombre.toUpperCase(), 'sentidoDebate': dirText});

      if (!mounted) return;
      await showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
          title: const FaIcon(FontAwesomeIcons.bullhorn, color: lobbyGold, size: 50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("ORDEN DE DEBATE", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 1.5)),
              const SizedBox(height: 20), const Text("EMPIEZA A HABLAR:", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(jugadorInicial.nombre.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: lobbyGold)),
              const SizedBox(height: 20), const Text("SENTIDO:", style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [FaIcon(dirIcon, color: textMain, size: 24), const SizedBox(width: 10), Text(dirText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textMain))]),
            ],
          ),
          actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "¡A DEBATIR!", onPressed: () => Navigator.pop(context))))],
        ),
      );
    }

    if (widget.config.rolSilencioso && vivos.isNotEmpty) {
      final victima = vivos[Random().nextInt(vivos.length)];
      setState(() => victima.estaSilenciado = true);
      if (!mounted) return;
      await showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelRed, width: 2)), title: const FaIcon(FontAwesomeIcons.microphoneSlash, color: jewelRed, size: 50), content: Text("EL SILENCIOSO HA ACTUADO\n\n${victima.nombre.toUpperCase()} NO PUEDE HABLAR ESTE TURNO.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)), actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "OK", onPressed: () => Navigator.pop(context))))]));
    }

    if (widget.config.rolDetective && vivos.isNotEmpty) {
      final detective = vivos[Random().nextInt(vivos.length)];
      setState(() => detective.esDetective = true);
      if (!mounted) return;
      await showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelBlue, width: 2)), title: const FaIcon(FontAwesomeIcons.magnifyingGlass, color: jewelBlue, size: 50), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("¡NUEVO DETECTIVE!", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)), const SizedBox(height: 10), Text(detective.nombre.toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: jewelBlue)), const SizedBox(height: 20), const Text("Debe hacer una pregunta indirecta a un jugador de su elección.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16))]), actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "ENTENDIDO", onPressed: () => Navigator.pop(context))))]));
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get formatoTiempo {
    int s = widget.config.modoContraReloj ? _segundosRestantes : _segundosTranscurridos;
    int min = s ~/ 60; int seg = s % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  Future<void> _guardarPuntajesEnDisco() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('puntajes', jsonEncode(widget.puntajes));
  }

  void _iniciarVotacionHibrida() async {
    _procesandoVotos = false;
    await FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/votos').remove();
    await FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'votacion_anonima'});

    List<JugadorEnPartida> vivos = widget.listaJugadores.where((j) => j.estaVivo).toList();

    showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) {
          return StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/votos').onValue,
              builder: (context, snap) {
                Map votos = snap.hasData && snap.data!.snapshot.value != null ? snap.data!.snapshot.value as Map : {};

                if (votos.length >= vivos.length && !_procesandoVotos) {
                  _procesandoVotos = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(ctx);
                    _mostrarConteoVotos(votos);
                  });
                }

                return AlertDialog(
                    backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGold, width: 2)),
                    title: const Text("VOTACIÓN SECRETA", textAlign: TextAlign.center, style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold)),
                    content: SizedBox(
                        width: double.maxFinite, height: 350,
                        child: ListView(
                            children: vivos.map((j) {
                              bool yaVoto = votos.containsKey(j.nombre);
                              bool esWeb = widget.jugadoresReclamadosWeb?.contains(j.nombre) ?? false;

                              if (yaVoto) {
                                return ListTile(title: Text(j.nombre.toUpperCase(), style: const TextStyle(color: jewelGreen, fontWeight: FontWeight.bold)), trailing: const FaIcon(FontAwesomeIcons.check, color: jewelGreen));
                              } else if (esWeb) {
                                return ListTile(title: Text(j.nombre.toUpperCase(), style: const TextStyle(color: textMuted)), trailing: const Text("Votando en Web...", style: TextStyle(color: lobbyGoldDark, fontSize: 12)));
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: lobbyGoldDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: Text("VOTAR: ${j.nombre.toUpperCase()}"),
                                    onPressed: () => _mostrarVotacionLocalRapida(ctx, j.nombre, vivos),
                                  ),
                                );
                              }
                            }).toList()
                        )
                    )
                );
              }
          );
        }
    );
  }

  void _mostrarVotacionLocalRapida(BuildContext parentCtx, String votante, List<JugadorEnPartida> vivos) {
    showDialog(
        context: parentCtx,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1510), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelRed, width: 2)),
            title: Text("Elige en secreto: $votante", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            content: SizedBox(
                width: double.maxFinite, height: 300,
                child: ListView(
                    children: vivos.map((j) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ebonyInput, foregroundColor: textMain),
                          child: Text(j.nombre),
                          onPressed: () { FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/votos/$votante').set(j.nombre); Navigator.pop(ctx); }
                      ),
                    )).toList()
                )
            )
        )
    );
  }

  void _mostrarConteoVotos(Map votos) async {
    if (widget.codigoSala != null) FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'contando_votos'});

    Map<String, int> conteo = {};
    votos.forEach((k, v) { conteo[v.toString()] = (conteo[v.toString()] ?? 0) + 1; });
    var listaOrdenada = conteo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    String? expulsado; int maxVotos = listaOrdenada.isNotEmpty ? listaOrdenada[0].value : 0;
    if (listaOrdenada.length == 1) { expulsado = listaOrdenada[0].key; }
    else if (listaOrdenada.length > 1) { if (listaOrdenada[0].value > listaOrdenada[1].value) { expulsado = listaOrdenada[0].key; } }

    await showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGold, width: 2)),
            title: const Text("RESULTADOS", textAlign: TextAlign.center, style: TextStyle(color: lobbyGold, fontSize: 24, fontWeight: FontWeight.bold)),
            content: SizedBox(
                width: 300,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...listaOrdenada.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [Text("${e.value}", style: const TextStyle(color: jewelRed, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(width: 5), const FaIcon(FontAwesomeIcons.ticket, color: jewelRed, size: 16)])]))).toList(),
                      const Divider(color: goldDark, height: 30, thickness: 2),
                      Text(expulsado != null ? "¡$expulsado ES EXPULSADO!" : "¡EMPATE! NADIE SALE.", textAlign: TextAlign.center, style: TextStyle(color: expulsado != null ? jewelRed : jewelBlue, fontSize: 20, fontWeight: FontWeight.w900))
                    ]
                )
            ),
            actions: [Center(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: lobbyGoldDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), onPressed: () => Navigator.pop(ctx), child: const Text("CONTINUAR", style: TextStyle(fontWeight: FontWeight.bold))))]
        )
    );

    if (expulsado != null) ejecutarExpulsion(widget.listaJugadores.firstWhere((j) => j.nombre == expulsado));
    else ejecutarEventosRonda();
  }

  void abrirVotacion() {
    if (widget.config.modoVotacionAnonima && widget.codigoSala != null) {
      _iniciarVotacionHibrida();
    } else if (widget.config.modoVotacionAnonima) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaVotacionTurnos(listaJugadores: widget.listaJugadores, onTerminarVotacion: (nombre) { if (nombre != null) ejecutarExpulsion(widget.listaJugadores.firstWhere((j) => j.nombre == nombre)); else ejecutarEventosRonda(); })));
    } else {
      showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
          title: const Text("¿A QUIÉN EXPULSAMOS?", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
          content: SizedBox(
            width: double.maxFinite, height: 300,
            child: ListView(children: widget.listaJugadores.where((j) => j.estaVivo).map((j) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GoldButton(text: j.nombre.toUpperCase(), colorOverride: ebonyInput, textColorOverride: textMain, onPressed: () { Navigator.pop(context); ejecutarExpulsion(j); }))).toList()),
          ),
          actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "SALTAR", colorOverride: ebonyInput, textColorOverride: textMuted, onPressed: () => Navigator.pop(context))))],
        ),
      );
    }
  }

  void ejecutarExpulsion(JugadorEnPartida jugador) {
    setState(() {
      jugador.estaVivo = false;
      if (widget.config.muerteSincronizada && jugador.esImpostor) { for (var j in widget.listaJugadores) { if (j.esImpostor) j.estaVivo = false; } }
    });

    if (widget.codigoSala != null) FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'revelacion_eliminado', 'eliminado_nombre': jugador.nombre.toUpperCase(), 'eliminado_esImpostor': jugador.esImpostor});

    showDialog(
        context: context, barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(seconds: 4), () { if (context.mounted) Navigator.pop(context); });
          return DialogoExpulsionAnimado(jugador: jugador);
        }
    ).then((_) { if (!verificarVictoria()) ejecutarEventosRonda(); });
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
        int pts = 0;
        if (j.esComplice) { pts = (!gananInocentes) ? 2 : 0; } else if (j.esImpostor) { pts = (!gananInocentes) ? 3 : 0; } else { pts = (gananInocentes) ? 1 : 0; }
        if (pts > 0) widget.puntajes[j.nombre] = (widget.puntajes[j.nombre] ?? 0) + pts;
      }
    });
    _guardarPuntajesEnDisco();

    if (widget.codigoSala != null) {
      FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({
        'estado': 'puntajes',
        'resultados': {'ganador': gananInocentes ? "INOCENTES" : "IMPOSTORES", 'puntajes': widget.puntajes, 'tiempoFinal': formatoTiempo}
      });
    }
  }

  void ejecutarEventosRonda() async {
    if (widget.config.modoCaos) {
      final nuevaCarta = widget.packUsado[Random().nextInt(widget.packUsado.length)];
      if (!mounted) return;
      await showDialog(
        context: context, builder: (context) => AlertDialog(backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelPurple, width: 2)), title: const FaIcon(FontAwesomeIcons.shuffle, color: jewelPurple, size: 50), content: const Text("¡MODO CAOS!\n\nLA PALABRA HA CAMBIADO.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)), actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "ENTENDIDO", onPressed: () => Navigator.pop(context))))]),
      );
      if (!mounted) return;

      if (widget.codigoSala != null) {
        FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/jugadores').get().then((snap) {
          if(snap.exists) {
            Map map = snap.value as Map;
            map.forEach((k,v) { FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/jugadores/$k').update({'listo': false}); });
          }
        });
        FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'revelando_roles', 'carta': {'palabra': nuevaCarta.palabra, 'pista': nuevaCarta.pista, 'categoria': nuevaCarta.categoria, 'mostrarCategoria': widget.config.mostrarCategoria.toString(), 'impostorTienePista': widget.config.impostorTienePista}});
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaJuego(listaJugadores: widget.listaJugadores, puntajes: widget.puntajes, carta: nuevaCarta, config: widget.config, packUsado: widget.packUsado, codigoSala: widget.codigoSala, jugadoresReclamadosWeb: widget.jugadoresReclamadosWeb)));
    } else {
      if (widget.codigoSala != null) FirebaseDatabase.instance.ref('salas/${widget.codigoSala}').update({'estado': 'debate'});
    }
  }

  void abrirDialogoCastigo() {
    showDialog(
      context: context, builder: (context) => AlertDialog(backgroundColor: ebonyCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelRed, width: 2)), title: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.bolt, color: jewelRed), SizedBox(width: 10), Text("CASTIGAR A...", style: TextStyle(color: jewelRed))]), content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(itemCount: widget.listaJugadores.length, itemBuilder: (context, index) { final jugador = widget.listaJugadores[index]; return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: GoldButton(text: "${jugador.nombre.toUpperCase()} (${widget.puntajes[jugador.nombre]})", colorOverride: ebonyInput, textColorOverride: textMain, onPressed: () {
      setState(() { widget.puntajes[jugador.nombre] = (widget.puntajes[jugador.nombre] ?? 0) - 1; _puntoQuitado = true; _jugadorCastigado = jugador.nombre; }); _guardarPuntajesEnDisco();
      if (widget.codigoSala != null) FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/resultados/puntajes').set(widget.puntajes);
      Navigator.pop(context); Sonidos.playReveal();
    })); })), actions: [Center(child: SizedBox(width: 200, child: GoldButton(text: "CANCELAR", colorOverride: ebonyInput, textColorOverride: textMuted, onPressed: () => Navigator.pop(context))))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrarResultadosFinales) {
      int vivos = widget.listaJugadores.where((j) => j.estaVivo).length;
      return PopScope(
        canPop: false, onPopInvoked: (didPop) async { if (didPop) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MenuLobby()), (route) => false); },
        child: Scaffold(
          backgroundColor: const Color(0xFF150A0A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: jewelRed, width: 4), color: ebonyInput), child: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 70, color: jewelRed)),
                const SizedBox(height: 30), Text(widget.config.modoContraReloj ? "TIEMPO RESTANTE" : "ENCUENTREN AL\nIMPOSTOR", textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 2.0)),
                const SizedBox(height: 15), Text(formatoTiempo, style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: jewelRed, fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 10), Text("$vivos JUGADORES VIVOS", style: const TextStyle(color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 60), SizedBox(width: 220, child: GoldButton(text: "VOTAR", onPressed: abrirVotacion)),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, onPopInvoked: (didPop) async { if (didPop) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MenuLobby(puntajesGuardados: widget.puntajes, configGuardada: widget.config, salaReconectada: widget.codigoSala)), (r) => false); },
      child: Scaffold(
        body: DuoFondo(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20), Text(ganadorMensaje, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorGanador, letterSpacing: 2.0)),
                  const SizedBox(height: 10), Text("TIEMPO: $formatoTiempo", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                  const SizedBox(height: 30),
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15), decoration: BoxDecoration(color: ebonyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: lobbyGoldDark, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 10)]), child: Column(children: [Text(widget.config.modoCaos ? "ÚLTIMA PALABRA:" : "LA PALABRA ERA:", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.5)), const SizedBox(height: 5), Text(widget.carta.palabra.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: lobbyGold, letterSpacing: 1.0))])),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: ebonyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: goldDark, width: 1.5)),
                      child: ListView.builder(
                        itemCount: widget.listaJugadores.length,
                        itemBuilder: (context, index) {
                          final jugador = widget.listaJugadores[index]; int pts = widget.puntajes[jugador.nombre] ?? 0;
                          int ganancia = 0; if (jugador.esComplice) { ganancia = (!ganaronInocentes) ? 2 : 0; } else if (jugador.esImpostor) { ganancia = (!ganaronInocentes) ? 3 : 0; } else { ganancia = (ganaronInocentes) ? 1 : 0; }
                          return ScoreItemAnimado(nombre: jugador.nombre, esImpostor: jugador.esImpostor, esComplice: jugador.esComplice, estaVivo: jugador.estaVivo, puntajeFinal: pts, ganancia: ganancia, fueCastigado: (jugador.nombre == _jugadorCastigado));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (!_puntoQuitado) ...[Expanded(flex: 1, child: GoldButton(text: "", icon: FontAwesomeIcons.bolt, colorOverride: ebonyInput, textColorOverride: jewelRed, onPressed: abrirDialogoCastigo)), const SizedBox(width: 10)],
                      Expanded(
                        flex: 3,
                        child: GoldButton(text: "JUGAR OTRA VEZ", onPressed: () {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MenuLobby(puntajesGuardados: widget.puntajes, configGuardada: widget.config, salaReconectada: widget.codigoSala)), (r) => false);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}