// lib/models.dart

// 1. CLASE CARTA
class CartaJuego {
  final String palabra;
  final String pista;
  final String categoria;

  CartaJuego(this.palabra, this.pista, {this.categoria = ""});

  Map<String, dynamic> toJson() => {'palabra': palabra, 'pista': pista, 'categoria': categoria};

  factory CartaJuego.fromJson(Map<String, dynamic> json) {
    return CartaJuego(
        json['palabra'],
        json['pista'],
        categoria: json['categoria'] ?? ""
    );
  }
}

// 🔥 NUEVO: ENUM PARA LOS 4 ESTADOS DE LA CATEGORÍA
enum VisibilidadCategoria {
  desactivado,
  soloInocentes,
  soloImpostor,
  todos
}

// 2. CONFIGURACIÓN GLOBAL DEL JUEGO
class ConfiguracionJuego {
  bool modoContraReloj;
  int minutosReloj;
  bool modoCaos;
  bool modoVotacionAnonima;

  // 🔥 NUEVA VARIABLE DE CATEGORÍA
  VisibilidadCategoria mostrarCategoria;

  bool impostorTienePista;
  bool impostoresSeConocen;
  bool muerteSincronizada;

  bool rolSilencioso;
  bool rolDetective;
  bool rolComplice;

  Map<String, bool> categoriasActivas;

  ConfiguracionJuego({
    this.modoContraReloj = false,
    this.minutosReloj = 5,
    this.modoCaos = false,
    this.modoVotacionAnonima = false,
    this.mostrarCategoria = VisibilidadCategoria.desactivado, // Por defecto desactivado
    this.impostorTienePista = false,
    this.impostoresSeConocen = false,
    this.muerteSincronizada = false,
    this.rolSilencioso = false,
    this.rolDetective = false,
    this.rolComplice = false,
    required this.categoriasActivas,
  });
}

// 3. JUGADOR DURANTE LA PARTIDA
class JugadorEnPartida {
  final String nombre;
  final bool esImpostor;
  final bool esComplice;
  bool esDetective;
  bool estaVivo;
  bool estaSilenciado;
  final String? rutaFoto;

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