// lib/models.dart

// 1. CLASE CARTA
class CartaJuego {
  final String palabra;
  final String pista;
  final String categoria;

  CartaJuego(this.palabra, this.pista, {this.categoria = ""});

  Map<String, dynamic> toJson() => {
    'palabra': palabra,
    'pista': pista,
    'categoria': categoria
  };

  factory CartaJuego.fromJson(Map<dynamic, dynamic> json) {
    return CartaJuego(
        json['palabra'] ?? "",
        json['pista'] ?? "",
        categoria: json['categoria'] ?? ""
    );
  }
}

// 🔥 ENUM PARA LOS 4 ESTADOS DE LA CATEGORÍA
enum VisibilidadCategoria {
  desactivado,
  soloInocentes,
  soloImpostor,
  todos
}

// Extensiones para convertir el Enum a String y viceversa (Necesario para Firebase)
extension VisibilidadCategoriaExtension on VisibilidadCategoria {
  String get name => toString().split('.').last;
}

VisibilidadCategoria visibilidadCategoriaFromString(String status) {
  return VisibilidadCategoria.values.firstWhere(
          (e) => e.name == status,
      orElse: () => VisibilidadCategoria.desactivado
  );
}

// 2. CONFIGURACIÓN GLOBAL DEL JUEGO
class ConfiguracionJuego {
  bool modoContraReloj;
  int minutosReloj;
  bool modoCaos;
  bool modoVotacionAnonima;

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
    this.mostrarCategoria = VisibilidadCategoria.desactivado,
    this.impostorTienePista = false,
    this.impostoresSeConocen = false,
    this.muerteSincronizada = false,
    this.rolSilencioso = false,
    this.rolDetective = false,
    this.rolComplice = false,
    required this.categoriasActivas,
  });

  // Para enviar a Firebase
  Map<String, dynamic> toJson() => {
    'modoContraReloj': modoContraReloj,
    'minutosReloj': minutosReloj,
    'modoCaos': modoCaos,
    'modoVotacionAnonima': modoVotacionAnonima,
    'mostrarCategoria': mostrarCategoria.name, // Guardamos como String
    'impostorTienePista': impostorTienePista,
    'impostoresSeConocen': impostoresSeConocen,
    'muerteSincronizada': muerteSincronizada,
    'rolSilencioso': rolSilencioso,
    'rolDetective': rolDetective,
    'rolComplice': rolComplice,
    'categoriasActivas': categoriasActivas,
  };

  // Para leer de Firebase
  factory ConfiguracionJuego.fromJson(Map<dynamic, dynamic> json) {
    return ConfiguracionJuego(
      modoContraReloj: json['modoContraReloj'] ?? false,
      minutosReloj: json['minutosReloj'] ?? 5,
      modoCaos: json['modoCaos'] ?? false,
      modoVotacionAnonima: json['modoVotacionAnonima'] ?? false,
      mostrarCategoria: visibilidadCategoriaFromString(json['mostrarCategoria'] ?? 'desactivado'),
      impostorTienePista: json['impostorTienePista'] ?? false,
      impostoresSeConocen: json['impostoresSeConocen'] ?? false,
      muerteSincronizada: json['muerteSincronizada'] ?? false,
      rolSilencioso: json['rolSilencioso'] ?? false,
      rolDetective: json['rolDetective'] ?? false,
      rolComplice: json['rolComplice'] ?? false,
      categoriasActivas: Map<String, bool>.from(json['categoriasActivas'] ?? {}),
    );
  }
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

  // 🔥 NUEVO: Identificador del celular que escaneó este rol.
  // Si es null, pertenece al celular Líder.
  String? reclamadoPorId;

  JugadorEnPartida({
    required this.nombre,
    required this.esImpostor,
    this.esComplice = false,
    this.esDetective = false,
    this.estaVivo = true,
    this.estaSilenciado = false,
    this.rutaFoto,
    this.reclamadoPorId,
  });

  // Para enviar a Firebase
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'esImpostor': esImpostor,
    'esComplice': esComplice,
    'esDetective': esDetective,
    'estaVivo': estaVivo,
    'estaSilenciado': estaSilenciado,
    'reclamadoPorId': reclamadoPorId,
    // Nota: La 'rutaFoto' local no se sube a Firebase porque las rutas
    // de galería de un celular no existen en los otros celulares.
  };

  // Para leer de Firebase
  factory JugadorEnPartida.fromJson(Map<dynamic, dynamic> json) {
    return JugadorEnPartida(
      nombre: json['nombre'] ?? '',
      esImpostor: json['esImpostor'] ?? false,
      esComplice: json['esComplice'] ?? false,
      esDetective: json['esDetective'] ?? false,
      estaVivo: json['estaVivo'] ?? true,
      estaSilenciado: json['estaSilenciado'] ?? false,
      reclamadoPorId: json['reclamadoPorId'],
      // La foto quedará en null para los celulares que no sean el host.
    );
  }
}