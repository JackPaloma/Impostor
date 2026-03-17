import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models.dart';

class SalaService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Genera un código aleatorio como "A4X9"
  String generarCodigoSala() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // EL LÍDER: Crea la sala en Firebase
  Future<String> crearSala(List<JugadorEnPartida> jugadores, ConfiguracionJuego config) async {
    String codigoSala = generarCodigoSala();
    DatabaseReference ref = _db.ref('salas/$codigoSala');

    // Convertimos la lista de jugadores a un Mapa para Firebase
    Map<String, dynamic> jugadoresJson = {};
    for (var j in jugadores) {
      jugadoresJson[j.nombre] = j.toJson();
    }

    await ref.set({
      'estado': 'lobby', // estados: lobby, revelando_roles, jugando, votacion
      'creadoEn': ServerValue.timestamp,
      'jugadores': jugadoresJson,
      // 'configuracion': config.toJson(), // Opcional, si quieres que los invitados vean las reglas
    });

    return codigoSala;
  }

  // LOS INVITADOS: Reclaman un jugador
  Future<void> reclamarJugador(String codigoSala, String nombreJugador, String miDeviceId) async {
    DatabaseReference ref = _db.ref('salas/$codigoSala/jugadores/$nombreJugador');
    await ref.update({
      'reclamadoPorId': miDeviceId
    });
  }

  // PARA TODOS: Escuchar los cambios en tiempo real
  Stream<DatabaseEvent> escucharSala(String codigoSala) {
    return _db.ref('salas/$codigoSala').onValue;
  }

  // EL LÍDER: Cambia la fase del juego
  Future<void> cambiarEstado(String codigoSala, String nuevoEstado) async {
    await _db.ref('salas/$codigoSala').update({'estado': nuevoEstado});
  }
}