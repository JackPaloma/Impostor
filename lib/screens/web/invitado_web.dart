import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:math';

import '../../theme.dart';
import '../../services/sala_service.dart';
import '../lobby/lobby_colors.dart';

class PantallaInvitadoWeb extends StatefulWidget {
  final String codigoSala;

  const PantallaInvitadoWeb({super.key, required this.codigoSala});

  @override
  State<PantallaInvitadoWeb> createState() => _PantallaInvitadoWebState();
}

class _PantallaInvitadoWebState extends State<PantallaInvitadoWeb> with SingleTickerProviderStateMixin {
  final SalaService _salaService = SalaService();
  final String miIdNavegador = "web_${Random().nextInt(9999999)}";
  String? miNombreReclamado;

  // Variables para la tarjeta deslizable
  double dragOffset = 0.0;
  bool tarjetaRevelada = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = const AlwaysStoppedAnimation(0.0);
    _animController.addListener(() => setState(() => dragOffset = _animation.value));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta.dy;
      if (dragOffset > 0) dragOffset = 0;
      if (dragOffset < -340) dragOffset = -340;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _animation = Tween<double>(begin: dragOffset, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0705),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
            stream: _salaService.escucharSala(widget.codigoSala),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: lobbyGold));
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text("La sala se ha cerrado.", style: TextStyle(color: jewelRed, fontSize: 18)));

              Map<dynamic, dynamic> sala = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              String estado = sala['estado'] ?? 'lobby';
              Map<dynamic, dynamic> jugadores = sala['jugadores'] ?? {};
              Map<dynamic, dynamic> config = sala['configuracion'] ?? {};
              Map<dynamic, dynamic>? carta = sala['carta'];

              // Recuperar Identidad si la web se recarga
              if (miNombreReclamado == null) {
                jugadores.forEach((nombre, datos) { if (datos['reclamadoPorId'] == miIdNavegador) miNombreReclamado = nombre; });
              }

              // 1. CANCELADA
              if (estado == 'cancelada') {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.circleXmark, color: jewelRed, size: 80), SizedBox(height: 20), Text("PARTIDA CANCELADA", style: TextStyle(color: jewelRed, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("El Host cerró el juego.", style: TextStyle(color: textMuted, fontSize: 16))]));
              }

              // 2. LOBBY
              if (estado == 'lobby') {
                tarjetaRevelada = false; // Reiniciamos para la próxima partida
                if (miNombreReclamado != null) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const FaIcon(FontAwesomeIcons.circleCheck, color: jewelGreen, size: 80), const SizedBox(height: 20), Text("¡Listo, $miNombreReclamado!", style: const TextStyle(color: lobbyGold, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text("Esperando a que el Líder inicie la partida...", textAlign: TextAlign.center, style: TextStyle(color: textMuted)), const SizedBox(height: 40), const CircularProgressIndicator(color: lobbyGoldDark)]));
                }
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("SALA CONECTADA", style: TextStyle(color: jewelGreen, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Text(widget.codigoSala, style: const TextStyle(color: lobbyGold, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 5)),
                      const SizedBox(height: 20), const Text("¿Quién eres?", style: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: jugadores.length,
                          itemBuilder: (context, index) {
                            String nombre = jugadores.keys.elementAt(index);
                            bool estaReclamado = jugadores[nombre]['reclamadoPorId'] != null;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: estaReclamado ? const Color(0xFF1E1510) : const Color(0xFF2A1B0E), borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: estaReclamado ? null : () async {
                                    await FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/jugadores/$nombre').update({'reclamadoPorId': miIdNavegador});
                                    setState(() => miNombreReclamado = nombre);
                                  },
                                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(nombre, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: estaReclamado ? textMuted : textMain, decoration: estaReclamado ? TextDecoration.lineThrough : null)), if (!estaReclamado) const FaIcon(FontAwesomeIcons.chevronRight, color: lobbyGold, size: 18) else const Text("OCUPADO", style: TextStyle(color: jewelRed, fontSize: 12, fontWeight: FontWeight.bold))])),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                );
              }

              // 3. REVELANDO ROLES (Animación de deslizar hacia arriba)
              if (estado == 'revelando_roles' && miNombreReclamado != null) {
                if (tarjetaRevelada) {
                  return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.eyeSlash, color: textMuted, size: 60), SizedBox(height: 20), Text("Rol memorizado", style: TextStyle(color: lobbyGold, fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("Mira la pantalla del Líder...", style: TextStyle(color: textMuted, fontSize: 16))])
                  );
                }

                Map<dynamic, dynamic>? misDatos = jugadores[miNombreReclamado];
                if (misDatos == null) return const Center(child: CircularProgressIndicator(color: lobbyGold));

                bool esImpostor = misDatos['esImpostor'] ?? false;
                bool esComplice = misDatos['esComplice'] ?? false;

                // Lógica de Categoría Exacta
                String visCategoria = config['mostrarCategoria']?.toString() ?? 'VisibilidadCategoria.todos';
                bool todosVen = visCategoria.contains('todos');
                bool soloInocentes = visCategoria.contains('soloInocentes');
                bool soloImpostor = visCategoria.contains('soloImpostor');

                String tituloRol = "INOCENTE"; Color colorIdentidad = jewelBlue; IconData iconoRol = FontAwesomeIcons.userShield;
                bool verPalabra = true; bool verCategoria = false; bool verPista = false;

                if (esImpostor) {
                  tituloRol = "IMPOSTOR"; colorIdentidad = jewelRed; iconoRol = FontAwesomeIcons.userSecret;
                  verPalabra = false; verCategoria = todosVen || soloImpostor; verPista = config['impostorTienePista'] ?? false;
                } else if (esComplice) {
                  tituloRol = "CÓMPLICE"; colorIdentidad = jewelPurple; iconoRol = FontAwesomeIcons.masksTheater;
                  verCategoria = todosVen;
                } else {
                  verCategoria = todosVen || soloInocentes;
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("TU TURNO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                      const SizedBox(height: 5),
                      Text(miNombreReclamado!.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textMain)),
                      const SizedBox(height: 30),

                      SizedBox(
                        height: 450, width: 300,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // TARJETA DE FONDO (EL ROL)
                            Container(
                              width: 300, height: 400,
                              decoration: BoxDecoration(color: const Color(0xFF1E1510), border: Border.all(color: colorIdentidad, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(top: 110, bottom: 20, left: 15, right: 15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(iconoRol, size: 50, color: colorIdentidad), const SizedBox(height: 10),
                                    Text(tituloRol, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: colorIdentidad)),
                                    const SizedBox(height: 15),
                                    if (carta != null) ...[
                                      if (verPalabra) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF2A1B0E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF8B6B4A))), child: Text(carta['palabra'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain)))
                                      else if (!esImpostor && !esComplice) const Padding(padding: EdgeInsets.only(bottom: 10.0), child: Text("Palabra Oculta 🔒", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                      if (verCategoria) Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF2A1B0E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF8B6B4A))), child: Column(children: [const Text("CATEGORÍA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text((carta['categoria'] ?? "").toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorIdentidad))])),
                                      if (verPista) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(children: [const Text("PISTA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text(carta['pista'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain))])),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // TARJETA DESLIZABLE SUPERIOR
                            Transform.translate(
                              offset: Offset(0, dragOffset),
                              child: GestureDetector(
                                onVerticalDragUpdate: _onVerticalDragUpdate,
                                onVerticalDragEnd: _onVerticalDragEnd,
                                child: Container(
                                  width: 300, height: 420,
                                  decoration: BoxDecoration(color: const Color(0xFF1E1510), border: Border.all(color: lobbyGoldDark, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, -5))]),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 50),
                                      const FaIcon(FontAwesomeIcons.userSecret, size: 80, color: lobbyGold),
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: lobbyGold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => setState(() => tarjetaRevelada = true),
                        child: const Text("OCULTAR ROL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              }

              // 4. DEBATE (Con temporizador y quién empieza)
              if (estado == 'debate') {
                int? tiempoFin = sala['tiempoFin'];
                String? primerJugador = sala['primerJugador'];

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.comments, color: lobbyGold, size: 60),
                      const SizedBox(height: 15),
                      const Text("¡DEBATE!", style: TextStyle(color: textMain, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 20),

                      if (tiempoFin != null) TemporizadorWeb(tiempoFinMs: tiempoFin)
                      else const Text("Debatiendo...", style: TextStyle(color: lobbyGold, fontSize: 20, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 30),
                      if (primerJugador != null)
                        Container(
                          padding: const EdgeInsets.all(15), margin: const EdgeInsets.symmetric(horizontal: 30),
                          decoration: BoxDecoration(color: const Color(0xFF2A1B0E), borderRadius: BorderRadius.circular(16), border: Border.all(color: lobbyGoldDark)),
                          child: Column(
                            children: [
                              const Text("LA PREGUNTA INICIA CON:", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(primerJugador, style: const TextStyle(color: lobbyGold, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),
                      const Text("Habla con los demás.\nEl Líder controla las votaciones.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14)),
                    ],
                  ),
                );
              }

              // 5. REVELACIÓN DEL ELIMINADO
              if (estado == 'revelacion_eliminado') {
                String eliminado = sala['eliminado_nombre'] ?? "Nadie";
                bool eraImpostor = sala['eliminado_esImpostor'] ?? false;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(eliminado, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                          eraImpostor ? "ERA UN IMPOSTOR" : "NO ERA IMPOSTOR",
                          style: TextStyle(color: eraImpostor ? jewelGreen : jewelRed, fontSize: 24, fontWeight: FontWeight.w900)
                      ),
                      const SizedBox(height: 30),
                      const Text("Mira el celular del Líder...", style: TextStyle(color: textMuted)),
                    ],
                  ),
                );
              }

              // 6. RESULTADOS Y PUNTAJES (Sin botones de control)
              if (estado == 'puntajes') {
                Map<dynamic, dynamic> resultados = sala['resultados'] ?? {};
                String ganador = resultados['ganador'] ?? "EMPATE";
                Color colorGanador = ganador == "IMPOSTORES" ? jewelRed : (ganador == "INOCENTES" ? jewelBlue : lobbyGold);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("FIN DEL JUEGO", style: TextStyle(color: textMuted, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text("VICTORIA DE LOS\n$ganador", textAlign: TextAlign.center, style: TextStyle(color: colorGanador, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                      const SizedBox(height: 40),

                      const CircularProgressIndicator(color: lobbyGoldDark),
                      const SizedBox(height: 20),
                      const Text("Esperando a que el Líder\nempiece otra partida...", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)),
                    ],
                  ),
                );
              }

              return const Center(child: Text("Cargando...", style: TextStyle(color: textMuted)));
            }
        ),
      ),
    );
  }
}

// Widget del Cronómetro Web
class TemporizadorWeb extends StatefulWidget {
  final int tiempoFinMs;
  const TemporizadorWeb({super.key, required this.tiempoFinMs});
  @override
  State<TemporizadorWeb> createState() => _TemporizadorWebState();
}

class _TemporizadorWebState extends State<TemporizadorWeb> {
  late Timer _timer;
  int _restante = 0;

  @override
  void initState() {
    super.initState();
    _actualizarTiempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarTiempo());
  }

  void _actualizarTiempo() {
    if (mounted) {
      setState(() {
        _restante = ((widget.tiempoFinMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
        if (_restante < 0) _restante = 0;
      });
    }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int min = _restante ~/ 60; int sec = _restante % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(color: const Color(0xFF1E1510), borderRadius: BorderRadius.circular(20), border: Border.all(color: _restante <= 10 && _restante > 0 ? jewelRed : lobbyGold, width: 2)),
      child: Text("$min:${sec.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: _restante <= 10 && _restante > 0 ? jewelRed : lobbyGold, fontFamily: 'monospace')),
    );
  }
}