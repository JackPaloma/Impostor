class ConfiguracionJuego {
  bool modoContraReloj;
  int minutosReloj;
  bool modoCaos;
  bool modoVotacionAnonima;
  bool modoSoloCategoria; // <--- NUEVO CAMPO

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
    this.modoSoloCategoria = false, // <--- VALOR POR DEFECTO
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

class JugadorEnPartida {
  final String nombre;
  final bool esImpostor;
  final bool esComplice;
  bool esDetective;
  bool estaVivo;
  bool estaSilenciado;

  JugadorEnPartida({
    required this.nombre,
    required this.esImpostor,
    this.esComplice = false,
    this.esDetective = false,
    this.estaVivo = true,
    this.estaSilenciado = false
  });
}