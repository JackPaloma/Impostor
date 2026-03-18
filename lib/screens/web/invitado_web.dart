import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import '../../theme.dart';
import '../../widgets.dart';
import '../../services/sala_service.dart';
import '../lobby/lobby_colors.dart';

class PantallaInvitadoWeb extends StatefulWidget {
  final String codigoSala;

  const PantallaInvitadoWeb({super.key, required this.codigoSala});

  @override
  State<PantallaInvitadoWeb> createState() => _PantallaInvitadoWebState();
}

class _PantallaInvitadoWebState extends State<PantallaInvitadoWeb> {
  final SalaService _salaService = SalaService();
  final String miIdNavegador = "web_${Random().nextInt(9999999)}";
  String? miNombreReclamado;

  bool tarjetaRevelada = false;
  DatabaseReference? refDesconexion;

  @override
  void dispose() {
    refDesconexion?.onDisconnect().remove();
    super.dispose();
  }

  void _reclamarJugador(String nombre) async {
    refDesconexion = FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/jugadores/$nombre/reclamadoPorId');
    await refDesconexion!.onDisconnect().remove();
    await refDesconexion!.set(miIdNavegador);
    setState(() => miNombreReclamado = nombre);
  }

  Widget _buildAvatarUniversal(String? base64String, double size) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: const Color(0xFF2A1B0E), shape: BoxShape.circle, border: Border.all(color: lobbyGoldDark, width: 2)),
        child: Center(child: FaIcon(FontAwesomeIcons.userSecret, size: size * 0.5, color: lobbyGold)),
      );
    }
    try {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: lobbyGoldDark, width: 2)),
        child: ClipOval(child: Image.memory(base64Decode(base64String), width: size, height: size, fit: BoxFit.cover)),
      );
    } catch(e) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: const Color(0xFF2A1B0E), shape: BoxShape.circle, border: Border.all(color: lobbyGoldDark, width: 2)),
        child: Center(child: FaIcon(FontAwesomeIcons.userSecret, size: size * 0.5, color: lobbyGold)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0705),
      body: DuoFondo(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
              stream: _salaService.escucharSala(widget.codigoSala),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: lobbyGold));
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text("La sala se ha cerrado.", style: TextStyle(color: jewelRed, fontSize: 18)));

                Map<dynamic, dynamic> sala = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                String estado = sala['estado'] ?? 'lobby';
                Map<dynamic, dynamic> jugadores = sala['jugadores'] ?? {};
                Map<dynamic, dynamic>? carta = sala['carta'];
                Map<dynamic, dynamic> configSala = sala['configuracion'] ?? {};

                if (miNombreReclamado == null) {
                  jugadores.forEach((nombre, datos) { if (datos['reclamadoPorId'] == miIdNavegador) miNombreReclamado = nombre; });
                } else {
                  if (!jugadores.containsKey(miNombreReclamado)) miNombreReclamado = null;
                }

                if (estado == 'cancelada') return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.circleXmark, color: jewelRed, size: 80), SizedBox(height: 20), Text("PARTIDA CANCELADA", style: TextStyle(color: jewelRed, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("El Host cerró el juego.", style: TextStyle(color: textMuted, fontSize: 16))]));

                // ==========================================
                // 1. LOBBY WEB
                // ==========================================
                if (estado == 'lobby') {
                  tarjetaRevelada = false;
                  if (miNombreReclamado != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const FaIcon(FontAwesomeIcons.circleCheck, color: jewelGreen, size: 80), const SizedBox(height: 20), Text("¡Listo, $miNombreReclamado!", style: const TextStyle(color: lobbyGold, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text("Esperando a que el Líder inicie la partida...", textAlign: TextAlign.center, style: TextStyle(color: textMuted)), const SizedBox(height: 40), const CircularProgressIndicator(color: lobbyGoldDark)]));
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
                              Map<dynamic, dynamic> datosJugador = jugadores[nombre];
                              bool estaReclamado = datosJugador['reclamadoPorId'] != null;
                              String? fotoB64 = datosJugador['fotoBase64'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                    color: estaReclamado ? const Color(0xFF1E1510) : ebonyInput,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: goldDark, width: 1.5)
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: estaReclamado ? null : () => _reclamarJugador(nombre),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                      child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                _buildAvatarUniversal(fotoB64, 40),
                                                const SizedBox(width: 15),
                                                Text(nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: estaReclamado ? textMuted : textMain, decoration: estaReclamado ? TextDecoration.lineThrough : null)),
                                              ],
                                            ),
                                            if (!estaReclamado) const FaIcon(FontAwesomeIcons.chevronRight, color: lobbyGold, size: 18) else const Text("OCUPADO", style: TextStyle(color: jewelRed, fontSize: 12, fontWeight: FontWeight.bold))
                                          ]
                                      )
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

                // ==========================================
                // 2. REVELANDO ROLES
                // ==========================================
                if (estado == 'revelando_roles' && miNombreReclamado != null) {
                  Map<dynamic, dynamic>? misDatos = jugadores[miNombreReclamado];
                  if (misDatos == null) return const Center(child: CircularProgressIndicator(color: lobbyGold));

                  bool esImpostor = misDatos['esImpostor'] ?? false;
                  bool esComplice = misDatos['esComplice'] ?? false;
                  bool estoyListo = misDatos['listo'] ?? false;

                  if (estoyListo) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.checkDouble, color: jewelGreen, size: 80), SizedBox(height: 20), Text("¡ESTÁS LISTO!", style: TextStyle(color: jewelGreen, fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("Esperando a que todos (Host y Web)\npresionen 'Listo'...", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)), SizedBox(height: 40), CircularProgressIndicator(color: jewelGreen)]));
                  }

                  String visCategoria = carta?['mostrarCategoria']?.toString() ?? configSala['mostrarCategoria']?.toString() ?? '';
                  bool verCategoria = false;

                  if (visCategoria.contains('todos')) {
                    verCategoria = true;
                  } else if (visCategoria.contains('soloInocentes') && !esImpostor && !esComplice) {
                    verCategoria = true;
                  } else if (visCategoria.contains('soloImpostor') && esImpostor) {
                    verCategoria = true;
                  }

                  String tituloRol = "INOCENTE"; Color colorIdentidad = jewelBlue; IconData iconoRol = FontAwesomeIcons.userShield;
                  bool verPalabra = true; bool verPista = false;

                  if (esImpostor) {
                    tituloRol = "IMPOSTOR"; colorIdentidad = jewelRed; iconoRol = FontAwesomeIcons.userSecret;
                    verPalabra = false; verPista = carta?['impostorTienePista'] ?? configSala['impostorTienePista'] ?? false;
                  } else if (esComplice) {
                    tituloRol = "CÓMPLICE"; colorIdentidad = jewelPurple; iconoRol = FontAwesomeIcons.masksTheater;
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("TU TURNO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 2.0)),
                        const SizedBox(height: 5),
                        Text(miNombreReclamado!.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textMain)),
                        const SizedBox(height: 30),

                        tarjetaRevelada ?
                        // TARJETA MOSTRADA
                        Container(
                          width: 320, padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(color: const Color(0xFF1E1510), border: Border.all(color: colorIdentidad, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("TU ROL ES:", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, letterSpacing: 2)), const SizedBox(height: 15), FaIcon(iconoRol, size: 60, color: colorIdentidad), const SizedBox(height: 15), Text(tituloRol, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorIdentidad, letterSpacing: 2)), const SizedBox(height: 25),
                              if (carta != null) ...[
                                if (verPalabra) Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF2A1B0E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF8B6B4A))), child: Text(carta['palabra'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textMain)))
                                else if (!esImpostor && !esComplice) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Palabra Oculta 🔒", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
                                if (verCategoria && carta['categoria'] != null && carta['categoria'].toString().isNotEmpty)
                                  Padding(padding: const EdgeInsets.only(top: 15), child: Column(children: [const Text("CATEGORÍA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text((carta['categoria'] ?? "").toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorIdentidad))])),
                                if (verPista && carta['pista'] != null && carta['pista'].toString().isNotEmpty)
                                  Padding(padding: const EdgeInsets.only(top: 15), child: Column(children: [const Text("PISTA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)), Text(carta['pista'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain))])),
                              ],
                            ],
                          ),
                        ) :
                        // TARJETA OCULTA
                        Container(
                          width: 320, padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 25),
                          decoration: BoxDecoration(color: const Color(0xFF1E1510), border: Border.all(color: lobbyGoldDark, width: 2), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 8))]),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAvatarUniversal(misDatos['fotoBase64'], 110),
                              const SizedBox(height: 30), const Text("CONFIDENCIAL", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: lobbyGold)),
                              const SizedBox(height: 15), const Divider(color: goldDark, thickness: 2, indent: 20, endIndent: 20), const SizedBox(height: 15),
                              const Text("Presiona el botón para\nver tu rol en secreto.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textMuted)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔥 BOTÓN TOGGLE SEGURO (Click normal)
                        ElevatedButton.icon(
                          icon: FaIcon(tarjetaRevelada ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, color: const Color(0xFF2A1B0E)),
                          label: Text(tarjetaRevelada ? "OCULTAR ROL" : "VER MI ROL", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2A1B0E))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lobbyGold,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            side: const BorderSide(color: lobbyGoldDark, width: 2),
                          ),
                          onPressed: () => setState(() => tarjetaRevelada = !tarjetaRevelada),
                        ),

                        const SizedBox(height: 15),

                        // 🔥 BOTÓN LISTO
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: jewelGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () => FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/jugadores/$miNombreReclamado').update({'listo': true}),
                          child: const Text("¡ESTOY LISTO!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                }

                // ==========================================
                // 3. DEBATE
                // ==========================================
                if (estado == 'debate') {
                  int? tiempoFin = sala['tiempoFin'];
                  String? primerJugador = sala['primerJugador'];
                  String? sentidoDebate = sala['sentidoDebate'];

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

                        const SizedBox(height: 40),
                        if (primerJugador != null)
                          Container(
                            padding: const EdgeInsets.all(15), margin: const EdgeInsets.symmetric(horizontal: 30),
                            decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(16), border: Border.all(color: lobbyGoldDark, width: 2)),
                            child: Column(
                              children: [
                                const Text("LA PREGUNTA INICIA CON:", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildAvatarUniversal(jugadores[primerJugador]?['fotoBase64'], 40),
                                    const SizedBox(width: 10),
                                    Text(primerJugador, style: const TextStyle(color: lobbyGold, fontSize: 22, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (sentidoDebate != null) ...[
                                  const SizedBox(height: 10),
                                  Text("EN SENTIDO $sentidoDebate", style: const TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w900)),
                                ]
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),
                        const Text("Habla con los demás.\nEl Líder controla las votaciones.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14)),
                      ],
                    ),
                  );
                }

                // ==========================================
                // 4. VOTACIÓN ANÓNIMA WEB
                // ==========================================
                if (estado == 'votacion_anonima') {
                  List<dynamic> vivos = sala['vivos'] ?? [];
                  Map<dynamic, dynamic> votos = sala['votos'] ?? {};

                  if (votos.containsKey(miNombreReclamado)) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [FaIcon(FontAwesomeIcons.check, color: jewelGreen, size: 80), SizedBox(height: 20), Text("VOTO REGISTRADO", style: TextStyle(color: jewelGreen, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("Esperando a los demás...", style: TextStyle(color: textMuted, fontSize: 16))]));
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.userSecret, color: lobbyGold, size: 50), const SizedBox(height: 15),
                          const Text("VOTACIÓN SECRETA", style: TextStyle(color: lobbyGold, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 5),
                          const Text("¿Quién es el Impostor?", style: TextStyle(color: textMuted, fontSize: 16)), const SizedBox(height: 30),
                          Expanded(
                              child: ListView(
                                  children: vivos.map((nombre) {
                                    String? fotoB64 = jugadores[nombre]?['fotoBase64'];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: ebonyInput, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: lobbyGoldDark))),
                                        onPressed: () => FirebaseDatabase.instance.ref('salas/${widget.codigoSala}/votos/$miNombreReclamado').set(nombre),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            _buildAvatarUniversal(fotoB64, 40),
                                            const SizedBox(width: 15),
                                            Text(nombre.toString().toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList()
                              )
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (estado == 'contando_votos') {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            FaIcon(FontAwesomeIcons.checkToSlot, color: lobbyGold, size: 80),
                            SizedBox(height: 20),
                            Text("VOTACIÓN CERRADA", style: TextStyle(color: lobbyGold, fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Text("Mira la pantalla del Líder\npara ver los resultados...", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)),
                          ]
                      )
                  );
                }

                // ==========================================
                // 5. REVELACIÓN DEL ELIMINADO
                // ==========================================
                if (estado == 'revelacion_eliminado') {
                  String eliminado = sala['eliminado_nombre'] ?? "Nadie";
                  bool eraImpostor = sala['eliminado_esImpostor'] ?? false;

                  String? fotoEliminado;
                  jugadores.forEach((k, v) { if (k.toString().toUpperCase() == eliminado.toUpperCase()) fotoEliminado = v['fotoBase64']; });

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatarUniversal(fotoEliminado, 150),
                        const SizedBox(height: 20),
                        Text(eliminado, style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900)),
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

                // ==========================================
                // 6. RESULTADOS FINALES Y PUNTAJES
                // ==========================================
                if (estado == 'puntajes') {
                  Map<dynamic, dynamic> resultados = sala['resultados'] ?? {};
                  String ganador = resultados['ganador'] ?? "EMPATE";
                  String tiempoFinal = resultados['tiempoFinal'] ?? "--:--";
                  Color colorGanador = ganador == "IMPOSTORES" ? jewelRed : (ganador == "INOCENTES" ? jewelBlue : lobbyGold);
                  Map<dynamic, dynamic> puntajesMap = resultados['puntajes'] ?? {};

                  var listaOrdenada = puntajesMap.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("FIN DEL JUEGO", style: TextStyle(color: textMuted, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 10),
                          Text("VICTORIA DE LOS\n$ganador", textAlign: TextAlign.center, style: TextStyle(color: colorGanador, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
                          const SizedBox(height: 10),
                          Text("TIEMPO: $tiempoFinal", style: const TextStyle(color: textMuted, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                            decoration: BoxDecoration(color: const Color(0xFF1E1510), borderRadius: BorderRadius.circular(20), border: Border.all(color: lobbyGoldDark, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 10)]),
                            child: Column(children: [
                              const Text("LA PALABRA ERA:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.5)),
                              const SizedBox(height: 5),
                              Text(carta?['palabra']?.toString().toUpperCase() ?? "???", textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: lobbyGold, letterSpacing: 1.0))
                            ]),
                          ),
                          const SizedBox(height: 20),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: ebonyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: goldDark, width: 1.5)),
                              child: ListView.builder(
                                  itemCount: listaOrdenada.length,
                                  itemBuilder: (context, index) {
                                    String nom = listaOrdenada[index].key.toString();
                                    String? fotoB64 = jugadores[nom]?['fotoBase64'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                        decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(16), border: Border.all(color: lobbyGoldDark, width: 1)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                _buildAvatarUniversal(fotoB64, 35),
                                                const SizedBox(width: 10),
                                                Text(nom, style: const TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 16)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: goldDark, borderRadius: BorderRadius.circular(8)),
                                              child: Text("${listaOrdenada[index].value} pts", style: const TextStyle(color: lobbyGold, fontWeight: FontWeight.w900, fontSize: 14)),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Text("Esperando a que el Líder\nempiece otra partida...", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(child: Text("Cargando...", style: TextStyle(color: textMuted)));
              }
          ),
        ),
      ),
    );
  }
}

class TemporizadorWeb extends StatefulWidget {
  final int tiempoFinMs;
  const TemporizadorWeb({super.key, required this.tiempoFinMs});
  @override
  State<TemporizadorWeb> createState() => _TemporizadorWebState();
}

class _TemporizadorWebState extends State<TemporizadorWeb> {
  late Timer _timer; int _restante = 0;

  @override
  void initState() { super.initState(); _actualizarTiempo(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarTiempo()); }
  void _actualizarTiempo() { if (mounted) { setState(() { _restante = ((widget.tiempoFinMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil(); if (_restante < 0) _restante = 0; }); } }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int min = _restante ~/ 60; int sec = _restante % 60;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(20), border: Border.all(color: _restante <= 10 && _restante > 0 ? jewelRed : lobbyGold, width: 2)), child: Text("$min:${sec.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: _restante <= 10 && _restante > 0 ? jewelRed : lobbyGold, fontFamily: 'monospace')));
  }
}