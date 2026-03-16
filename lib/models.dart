// ==========================================
// CONFIGURACIÓN GLOBAL DEL JUEGO
// ==========================================
class ConfiguracionJuego {
  bool modoContraReloj;
  int minutosReloj;
  bool modoCaos;
  bool modoVotacionAnonima;
  bool modoSoloCategoria;

  // Ajustes de Impostor
  bool impostorTienePista;
  bool impostoresSeConocen;
  bool muerteSincronizada;

  // NUEVOS ROLES
  bool rolSilencioso;
  bool rolDetective;
  bool rolComplice;

  Map<String, bool> categoriasActivas;

  ConfiguracionJuego({
    this.modoContraReloj = false,
    this.minutosReloj = 5,
    this.modoCaos = false,
    this.modoVotacionAnonima = false,
    this.modoSoloCategoria = false,
    this.impostorTienePista = false,
    this.impostoresSeConocen = false,
    this.muerteSincronizada = false,

    // Default roles false
    this.rolSilencioso = false,
    this.rolDetective = false,
    this.rolComplice = false,

    required this.categoriasActivas,
  });
}

// ==========================================
// JUGADOR DURANTE LA PARTIDA
// ==========================================
class JugadorEnPartida {
  final String nombre;
  final bool esImpostor;
  final bool esComplice;
  bool esDetective;
  bool estaVivo;
  bool estaSilenciado;
  final String? rutaFoto; // Mantenemos el soporte para fotos

  JugadorEnPartida({
    required this.nombre,
    required this.esImpostor,
    this.esComplice = false,
    this.esDetective = false,
    this.estaVivo = true,
    this.estaSilenciado = false,
    this.rutaFoto,
  });
}