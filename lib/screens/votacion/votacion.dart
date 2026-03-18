import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models.dart';
import '../../widgets.dart';

import 'votacion_colors.dart'; // 🔥 USA SOLO SUS PROPIOS COLORES
import 'votacion_components.dart';

class PantallaVotacionTurnos extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Function(String?) onTerminarVotacion;

  const PantallaVotacionTurnos({super.key, required this.listaJugadores, required this.onTerminarVotacion});

  @override
  State<PantallaVotacionTurnos> createState() => _PantallaVotacionTurnosState();
}

class _PantallaVotacionTurnosState extends State<PantallaVotacionTurnos> {
  late List<String> votantesVivos;
  int turnoIndex = 0;
  bool esperandoJugador = true;
  Map<String, int> conteoVotos = {};

  @override
  void initState() {
    super.initState();
    votantesVivos = widget.listaJugadores.where((j) => j.estaVivo).map((j) => j.nombre).toList();
    for (var j in widget.listaJugadores) {
      if (j.estaVivo) conteoVotos[j.nombre] = 0;
    }
  }

  void registrarVoto(String? votado) {
    if (votado != null) {
      conteoVotos[votado] = (conteoVotos[votado] ?? 0) + 1;
    }

    if (turnoIndex < votantesVivos.length - 1) {
      setState(() {
        turnoIndex++;
        esperandoJugador = true;
      });
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaConteoAnimado(
        listaJugadores: widget.listaJugadores,
        conteoVotos: conteoVotos,
        onTerminarAnimacion: widget.onTerminarVotacion,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ESTADO 1: ESPERANDO JUGADOR (PASE EL TELÉFONO) ---
    if (esperandoJugador) {
      String nombreJugador = votantesVivos[turnoIndex];
      return Scaffold(
        body: DuoFondo(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ebonyInput,
                        border: Border.all(color: lobbyGoldDark, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]
                    ),
                    child: const FaIcon(FontAwesomeIcons.personBooth, size: 70, color: lobbyGold),
                  ),
                  const SizedBox(height: 50),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text("PÁSALE EL TELÉFONO A:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 4.0..color = Colors.black)),
                      const Text("PÁSALE EL TELÉFONO A:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: lobbyGold)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(nombreJugador.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 6.0..color = Colors.black)),
                      Text(nombreJugador.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5, color: lobbyGold, shadows: [Shadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 8)])),
                    ],
                  ),
                  const SizedBox(height: 60),

                  SizedBox(
                    width: 220,
                    child: GoldButton(text: "SOY YO", onPressed: () => setState(() => esperandoJugador = false)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // --- ESTADO 2: SELECCIÓN DE VOTO SECRETO ---
    String votanteActual = votantesVivos[turnoIndex];

    return Scaffold(
      body: DuoFondo(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                      color: ebonyCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: lobbyGoldDark, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))]
                  ),
                  child: Column(
                    children: [
                      const Text("VOTO SECRETO 🤫", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: jewelRed, letterSpacing: 2.0)),
                      const SizedBox(height: 5),
                      Text("Estás votando como: $votanteActual", style: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.listaJugadores.length,
                  itemBuilder: (context, index) {
                    final candidato = widget.listaJugadores[index];
                    if (!candidato.estaVivo) return const SizedBox();
                    if (candidato.nombre == votanteActual) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoldButton(
                        text: candidato.nombre.toUpperCase(),
                        colorOverride: ebonyInput,
                        textColorOverride: textMain,
                        onPressed: () => registrarVoto(candidato.nombre),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GoldButton(
                  text: "SALTAR (NADIE)",
                  colorOverride: ebonyCard,
                  textColorOverride: textMuted,
                  onPressed: () => registrarVoto(null),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA DE CONTEO ANIMADO ---
class PantallaConteoAnimado extends StatefulWidget {
  final List<JugadorEnPartida> listaJugadores;
  final Map<String, int> conteoVotos;
  final Function(String?) onTerminarAnimacion;

  const PantallaConteoAnimado({super.key, required this.listaJugadores, required this.conteoVotos, required this.onTerminarAnimacion});

  @override
  State<PantallaConteoAnimado> createState() => _PantallaConteoAnimadoState();
}

class _PantallaConteoAnimadoState extends State<PantallaConteoAnimado> {
  Map<String, int> votosVisibles = {};

  @override
  void initState() {
    super.initState();
    for (var j in widget.listaJugadores) {
      if (j.estaVivo) votosVisibles[j.nombre] = 0;
    }
    _iniciarSecuenciaVotos();
  }

  void _iniciarSecuenciaVotos() async {
    int maxVotos = 0;
    widget.conteoVotos.forEach((key, value) {
      if (value > maxVotos) maxVotos = value;
    });

    await Future.delayed(const Duration(seconds: 1));

    for (int i = 1; i <= maxVotos; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        widget.conteoVotos.forEach((nombre, total) {
          if (total >= i) {
            votosVisibles[nombre] = i;
          }
        });
      });
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _calcularResultado();
  }

  void _calcularResultado() {
    String? eliminado;
    int maxVotos = -1;
    bool empate = false;

    widget.conteoVotos.forEach((nombre, votos) {
      if (votos > maxVotos) {
        maxVotos = votos;
        eliminado = nombre;
        empate = false;
      } else if (votos == maxVotos) {
        empate = true;
      }
    });

    if (empate) eliminado = null;

    Navigator.pop(context);
    widget.onTerminarAnimacion(eliminado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DuoFondo(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                      color: lobbyGold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))]
                  ),
                  child: const Text("RESULTADOS", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2A1B0E), letterSpacing: 3.0)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.listaJugadores.length,
                  itemBuilder: (context, index) {
                    final jugador = widget.listaJugadores[index];
                    if (!jugador.estaVivo) return const SizedBox();

                    int votos = votosVisibles[jugador.nombre] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: ebonyCard,
                          border: Border.all(color: lobbyGoldDark, width: 1.5),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 5)]
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(jugador.nombre.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMain)),
                          ),
                          Container(width: 2, height: 30, color: goldDark),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: List.generate(votos, (i) => const FaIcon(FontAwesomeIcons.xmark, color: jewelRed, size: 24)),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text("CONTANDO VOTOS...", style: TextStyle(color: textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}