import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

// Color Beige para consistencia visual
const Color duoBeige = Color(0xFFE3CA94);

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
      return Scaffold(
        backgroundColor: duoBg, // Fondo plano oscuro
        body: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
                color: duoBeige, // <--- TARJETA BEIGE (Estilo Lobby)
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: duoBorder, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 10), blurRadius: 10)]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.how_to_vote, size: 80, color: duoBg),
                const SizedBox(height: 20),
                Text("TURNO DE VOTAR", style: TextStyle(color: duoBg.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Text(votantesVivos[turnoIndex].toUpperCase(), textAlign: TextAlign.center, style: duoFont(size: 40, color: duoBg)),
                const SizedBox(height: 40),
                SizedBox(
                    width: 200,
                    child: DuoButton(
                        text: "VOTAR",
                        color: duoBg, // Botón oscuro sobre beige
                        onPressed: () => setState(() => esperandoJugador = false)
                    )
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- ESTADO 2: SELECCIÓN DE VOTO ---
    String votanteActual = votantesVivos[turnoIndex];

    return Scaffold(
      backgroundColor: duoBg, // Fondo plano
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                        color: duoSurface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: duoBorder)
                    ),
                    child: Column(
                      children: [
                        Text("VOTO SECRETO 🤫", style: duoFont(size: 20, color: const Color(0xFFFF9600))),
                        const SizedBox(height: 5),
                        Text("Estás votando como: $votanteActual", style: const TextStyle(color: duoTextSub, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
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
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DuoButton(
                      text: candidato.nombre,
                      color: duoSurface,
                      shadowColor: duoBorder,
                      onPressed: () => registrarVoto(candidato.nombre),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: DuoButton(
                text: "SALTAR VOTO (NADIE)",
                color: duoSurface.withOpacity(0.5),
                shadowColor: duoBorder,
                onPressed: () => registrarVoto(null),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE CONTEO ---
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
      backgroundColor: duoBg, // Fondo plano
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: duoBeige, // Cabecera Beige
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: duoBorder, width: 2)
                ),
                child: Text("RESULTADOS", style: duoFont(size: 30, color: duoBg)),
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
                        color: duoSurface,
                        border: Border.all(color: duoBorder, width: 2),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2))]
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(jugador.nombre, style: duoFont(size: 18, color: duoTextMain)),
                        ),
                        Container(width: 2, height: 30, color: duoBorder), // Separador
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: List.generate(votos, (i) => const Icon(Icons.how_to_vote, color: duoRed, size: 28)),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text("Contando votos...", style: TextStyle(color: duoTextSub, fontStyle: FontStyle.italic)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}