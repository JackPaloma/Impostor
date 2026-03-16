import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datos.dart';
import '../theme.dart';
import '../models.dart';
import '../widgets.dart';
import 'juego.dart';

// Definimos el nuevo color Beige/Dorado solicitado
const Color duoBeige = Color(0xFFE3CA94);

class MenuLobby extends StatefulWidget {
  final Map<String, int>? puntajesGuardados;
  final ConfiguracionJuego? configGuardada;

  const MenuLobby({super.key, this.puntajesGuardados, this.configGuardada});
  @override
  State<MenuLobby> createState() => _MenuLobbyState();
}

class _MenuLobbyState extends State<MenuLobby> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _palabraCtrl = TextEditingController();
  final TextEditingController _pistaCtrl = TextEditingController();
  final TextEditingController _categoriaCtrl = TextEditingController();

  Map<String, int> puntajes = {};
  List<String> jugadores = [];
  int cantidadImpostores = 1;
  bool usarPersonalizadas = false;
  List<CartaJuego> packPersonalizado = [];
  late ConfiguracionJuego config;

  @override
  void initState() {
    super.initState();
    if (widget.puntajesGuardados != null) {
      puntajes = widget.puntajesGuardados!;
      jugadores = puntajes.keys.toList();
    }

    if (widget.configGuardada != null) {
      config = widget.configGuardada!;
    } else {
      Map<String, bool> cats = {};
      for (var key in baseDeDatos.keys) {
        cats[key] = true;
      }
      config = ConfiguracionJuego(categoriasActivas: cats);
    }

    _cargarDatosGuardados();
  }

  // --- LÓGICA DE MÁXIMOS IMPOSTORES ---
  int get maxImpostoresPermitidos {
    if (jugadores.isEmpty) return 1;
    int max = jugadores.length ~/ 2;
    return max < 1 ? 1 : max;
  }

  Future<void> _cargarDatosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (widget.puntajesGuardados == null) {
        String? puntajesString = prefs.getString('puntajes');
        if (puntajesString != null) {
          Map<String, dynamic> decoded = jsonDecode(puntajesString);
          puntajes = decoded.map((key, value) => MapEntry(key, value as int));
          jugadores = puntajes.keys.toList();
        }
      }

      String? palabrasString = prefs.getString('palabras_propias');
      if (palabrasString != null) {
        List<dynamic> decodedList = jsonDecode(palabrasString);
        packPersonalizado = decodedList.map((item) => CartaJuego.fromJson(item)).toList();
      }
      usarPersonalizadas = prefs.getBool('usar_personalizadas') ?? false;

      cantidadImpostores = prefs.getInt('cantidad_impostores') ?? 1;
      if (cantidadImpostores > maxImpostoresPermitidos) {
        cantidadImpostores = maxImpostoresPermitidos;
      }
    });
  }

  Future<void> _guardarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('puntajes', jsonEncode(puntajes));
    List<Map<String, dynamic>> jsonList = packPersonalizado.map((e) => e.toJson()).toList();
    prefs.setString('palabras_propias', jsonEncode(jsonList));
    prefs.setBool('usar_personalizadas', usarPersonalizadas);
    prefs.setInt('cantidad_impostores', cantidadImpostores);
  }

  void agregarJugador() {
    String nombre = _nameCtrl.text.trim();
    if (nombre.isNotEmpty && !puntajes.containsKey(nombre)) {
      setState(() {
        puntajes[nombre] = 0;
        jugadores.add(nombre);
        _nameCtrl.clear();
      });
      _guardarTodo();
    }
  }

  void borrarJugador(int index) {
    setState(() {
      String nombre = jugadores[index];
      puntajes.remove(nombre);
      jugadores.removeAt(index);

      if (cantidadImpostores > maxImpostoresPermitidos) {
        cantidadImpostores = maxImpostoresPermitidos;
      }
    });
    _guardarTodo();
  }

  void agregarPalabra() {
    if (_palabraCtrl.text.isNotEmpty && _pistaCtrl.text.isNotEmpty && _categoriaCtrl.text.isNotEmpty) {
      setState(() {
        packPersonalizado.add(CartaJuego(
            _palabraCtrl.text,
            _pistaCtrl.text,
            categoria: _categoriaCtrl.text
        ));
        _palabraCtrl.clear();
        _pistaCtrl.clear();
        _categoriaCtrl.clear();
      });
      _guardarTodo();
      Navigator.pop(context);
    }
  }

  void borrarPalabraPersonalizada(int index) {
    setState(() => packPersonalizado.removeAt(index));
    _guardarTodo();
  }

  void gestionarPalabras() {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: duoSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text("MIS PALABRAS", style: duoFont(size: 24, color: AppTheme.primary)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: packPersonalizado.isEmpty
                      ? const Center(child: Text("Lista vacía", style: TextStyle(color: duoTextSub, fontSize: 16)))
                      : ListView.builder(
                    itemCount: packPersonalizado.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: duoBorder, width: 2))),
                        child: ListTile(
                          title: Text(packPersonalizado[index].palabra, style: duoFont(size: 18)),
                          subtitle: Text("Pista: ${packPersonalizado[index].pista}", style: const TextStyle(color: duoTextSub)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: duoRed),
                            onPressed: () {
                              borrarPalabraPersonalizada(index);
                              setStateDialog(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [Center(child: SizedBox(width: 150, child: DuoButton(text: "CERRAR", color: duoSurface, onPressed: () => Navigator.pop(context))))],
              );
            }
        )
    );
  }

  void mostrarDialogoCrear() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: duoSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("CREAR PALABRA", style: duoFont(size: 24, color: AppTheme.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DuoInput(controller: _palabraCtrl, hint: "Palabra (Ej: Batman)"),
                const SizedBox(height: 10),
                DuoInput(controller: _pistaCtrl, hint: "Pista (Ej: Héroe)"),
                const SizedBox(height: 10),
                DuoInput(controller: _categoriaCtrl, hint: "Categoría (Ej: Cine)"),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DuoButton(text: "CANCELAR", color: duoRed, onPressed: () => Navigator.pop(context)),
                DuoButton(text: "GUARDAR", color: AppTheme.primary, onPressed: agregarPalabra),
              ],
            )
          ],
        )
    );
  }

  void abrirConfiguracionGeneral() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: duoSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Icon(Icons.settings, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Text("AJUSTES", style: duoFont(size: 24, color: AppTheme.primary)),
                    ],
                  ),
                  content: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: duoBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: duoBorder)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("SONIDO", style: duoFont(size: 16, color: duoTextSub)),
                                IconButton(
                                  icon: Icon(
                                    AppTheme.sonidoActivado ? Icons.volume_up : Icons.volume_off,
                                    color: AppTheme.sonidoActivado ? AppTheme.primary : duoRed,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    AppTheme.toggleSound();
                                    setStateDialog(() {});
                                    setState(() {}); // <-- Actualiza la pantalla de fondo en tiempo real
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: duoBorder, height: 30),
                          const Text("TEMA PRINCIPAL", style: TextStyle(color: duoTextSub, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: Wrap(
                                spacing: 15,
                                runSpacing: 15,
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: AppTheme.colors.map((color) {
                                  bool isSelected = AppTheme.primary.toARGB32() == color.toARGB32();
                                  return GestureDetector(
                                    onTap: () {
                                      AppTheme.setColor(color);
                                      setStateDialog((){});
                                      setState((){}); // <-- Actualiza la pantalla de fondo en tiempo real
                                    },
                                    child: Container(
                                      width: 45, height: 45,
                                      decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))]
                                      ),
                                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [Center(child: SizedBox(width: 150, child: DuoButton(text: "LISTO", color: AppTheme.primary, onPressed: () => Navigator.pop(context))))],
                );
              }
          );
        }
    ).then((_) {
      if (mounted) setState(() {}); // Asegurarnos de que actualice al cerrar el modal
    });
  }

  void configurarModos() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: duoSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("REGLAS DEL JUEGO", style: duoFont(size: 24, color: AppTheme.primary)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: const Text("MODOS DE JUEGO", style: TextStyle(color: duoBlue, fontWeight: FontWeight.bold, fontSize: 16))),
                    _buildDuoSwitch("⏱️ Contra el Reloj", "Gana Impostor si acaba el tiempo.", config.modoContraReloj, (v) {
                      setStateDialog(() { config.modoContraReloj = v; if(v) config.modoCaos = false; });
                    }),
                    if (config.modoContraReloj)
                      Slider(value: config.minutosReloj.toDouble(), min: 2, max: 10, divisions: 8, label: "${config.minutosReloj} min", activeColor: AppTheme.primary, inactiveColor: duoBorder, onChanged: (val) => setStateDialog(() => config.minutosReloj = val.toInt())),
                    _buildDuoSwitch("🌀 Modo Caos", "Nueva palabra tras cada muerte.", config.modoCaos, (v) {
                      setStateDialog(() { config.modoCaos = v; if(v) config.modoContraReloj = false; });
                    }),

                    // --- MODO SOLO CATEGORÍA ---
                    _buildDuoSwitch("🏷️ Solo Categoría", "Los inocentes solo ven la categoría.", config.modoSoloCategoria, (v) {
                      setStateDialog(() {
                        config.modoSoloCategoria = v;
                        if(v) {
                          // Desactivamos roles y pistas incompatibles
                          config.rolSilencioso = false;
                          config.rolDetective = false;
                          config.rolComplice = false;
                          config.impostorTienePista = false;
                        }
                      });
                    }),
                    // ---------------------------------

                    const Divider(height: 20, color: duoBorder),

                    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: const Text("ROLES ESPECIALES", style: TextStyle(color: Color(0xFFB721FF), fontWeight: FontWeight.bold, fontSize: 16))),
                    _buildDuoSwitch("🤫 El Silencioso", "Silencia a uno al inicio del debate.", config.rolSilencioso, (v) => setStateDialog(() { config.rolSilencioso = v; if(v) config.modoSoloCategoria = false; })),
                    _buildDuoSwitch("🔍 Detective", "Pregunta indirecta a un jugador.", config.rolDetective, (v) => setStateDialog(() { config.rolDetective = v; if(v) config.modoSoloCategoria = false; })),
                    _buildDuoSwitch("🎭 Cómplice", "Inocente que ayuda a impostores (+2 pts).", config.rolComplice, (v) => setStateDialog(() { config.rolComplice = v; if(v) config.modoSoloCategoria = false; })),

                    const Divider(height: 20, color: duoBorder),

                    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: const Text("AJUSTES DE PARTIDA", style: TextStyle(color: Color(0xFFFF9600), fontWeight: FontWeight.bold, fontSize: 16))),
                    _buildDuoSwitch("🕵️ Pista Impostor", "El impostor ve la PISTA.", config.impostorTienePista, (v) {
                      setStateDialog(() { config.impostorTienePista = v; if(v) config.modoSoloCategoria = false; });
                    }),
                    _buildDuoSwitch("👥 Conocer Aliados", "Impostores saben quién es su socio.", config.impostoresSeConocen, (v) => setStateDialog(() => config.impostoresSeConocen = v)),
                    _buildDuoSwitch("💀 Sincronía Vital", "Si muere un Impostor, mueren TODOS.", config.muerteSincronizada, (v) => setStateDialog(() => config.muerteSincronizada = v)),
                    _buildDuoSwitch("🗳️ Votación Anónima", "Votos secretos y conteo.", config.modoVotacionAnonima, (v) => setStateDialog(() => config.modoVotacionAnonima = v)),
                  ],
                ),
              ),
              actions: [Center(child: SizedBox(width: 150, child: DuoButton(text: "LISTO", color: AppTheme.primary, onPressed: () => Navigator.pop(context))))],
            );
          }
      ),
    ).then((_) {
      if (mounted) setState((){});
    });
  }

  Widget _buildDuoSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: duoFont(size: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: duoTextSub, fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }

  void configurarCategorias() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: duoSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("PACKS DE PALABRAS", style: duoFont(size: 24, color: duoYellow)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: config.categoriasActivas.keys.map((cat) {
                    return CheckboxListTile(
                      title: Text(cat, style: duoFont(size: 16)),
                      value: config.categoriasActivas[cat] ?? false,
                      activeColor: AppTheme.primary,
                      checkColor: duoBg,
                      side: const BorderSide(color: duoTextSub),
                      onChanged: (bool? val) {
                        setStateDialog(() {
                          config.categoriasActivas[cat] = val!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [Center(child: SizedBox(width: 150, child: DuoButton(text: "LISTO", color: AppTheme.primary, onPressed: () => Navigator.pop(context))))],
            );
          }
      ),
    ).then((_) {
      if (mounted) setState((){});
    });
  }

  void iniciarPartida() {
    if (jugadores.length < 3) return;

    List<CartaJuego> poolPalabras = [];
    config.categoriasActivas.forEach((categoria, estaActiva) {
      if (estaActiva && baseDeDatos.containsKey(categoria)) {
        poolPalabras.addAll(
            baseDeDatos[categoria]!.map((c) => CartaJuego(c.palabra, c.pista, categoria: categoria))
        );
      }
    });

    if (usarPersonalizadas) {
      if (packPersonalizado.isNotEmpty) {
        poolPalabras.addAll(packPersonalizado);
      } else if (poolPalabras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡No hay palabras disponibles!", style: duoFont(size: 14)), backgroundColor: duoRed));
        return;
      }
    }

    if (poolPalabras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Activa al menos una categoría!", style: duoFont(size: 14)), backgroundColor: const Color(0xFFFF9600)));
      return;
    }

    final carta = poolPalabras[Random().nextInt(poolPalabras.length)];
    Set<int> indicesImpostores = {};
    while (indicesImpostores.length < cantidadImpostores) {
      indicesImpostores.add(Random().nextInt(jugadores.length));
    }

    // --- ASIGNAR CÓMPLICE ---
    int? indiceComplice;
    if (config.rolComplice) {
      List<int> posiblesComplices = [];
      for (int i = 0; i < jugadores.length; i++) {
        if (!indicesImpostores.contains(i)) {
          posiblesComplices.add(i);
        }
      }
      if (posiblesComplices.isNotEmpty) {
        indiceComplice = posiblesComplices[Random().nextInt(posiblesComplices.length)];
      }
    }

    List<JugadorEnPartida> listaJugadoresObj = List.generate(jugadores.length, (index) {
      return JugadorEnPartida(
          nombre: jugadores[index],
          esImpostor: indicesImpostores.contains(index),
          esComplice: (index == indiceComplice)
      );
    });

    Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaJuego(
      listaJugadores: listaJugadoresObj,
      puntajes: puntajes,
      carta: carta,
      config: config,
      packUsado: poolPalabras,
    )));
  }

  @override
  Widget build(BuildContext context) {
    int categoriasActivasCount = config.categoriasActivas.values.where((v) => v).length;
    String emojisActivos = "";
    if (config.modoContraReloj) emojisActivos += "⏱️ ";
    if (config.modoCaos) emojisActivos += "🌀 ";
    if (config.modoSoloCategoria) emojisActivos += "🏷️ ";
    if (config.rolSilencioso) emojisActivos += "🤫 ";
    if (config.impostorTienePista) emojisActivos += "🕵️ ";
    if (config.modoVotacionAnonima) emojisActivos += "🗳️ ";
    if (config.impostoresSeConocen) emojisActivos += "👥 ";
    if (config.muerteSincronizada) emojisActivos += "💀 ";
    if (config.rolDetective) emojisActivos += "🔍 ";
    if (config.rolComplice) emojisActivos += "🎭 ";
    if (emojisActivos.isEmpty) emojisActivos = "Clásico";

    int maxUI = maxImpostoresPermitidos;

    return Scaffold(
      body: DuoFondo(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text("IMPOSTOR", style: duoFont(size: 40, color: AppTheme.primary)),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.grey, size: 30),
                    onPressed: abrirConfiguracionGeneral,
                  )
                ],
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN PALABRAS PROPIAS ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: duoBeige, // <--- NUEVO COLOR
                    border: Border.all(color: duoBorder, width: 2),
                    borderRadius: BorderRadius.circular(16)
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PALABRAS PROPIAS", style: duoFont(size: 16, color: duoBg)),
                          Text(usarPersonalizadas ? "${packPersonalizado.length} activas" : "Desactivadas",
                              style: TextStyle(color: duoBg.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    Switch(
                        value: usarPersonalizadas,
                        activeColor: AppTheme.primary,
                        activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                        inactiveThumbColor: duoBg,
                        onChanged: (v) { setState(() => usarPersonalizadas = v); _guardarTodo(); }
                    ),
                    if (usarPersonalizadas) ...[
                      IconButton(icon: const Icon(Icons.list_alt, color: duoBg), onPressed: gestionarPalabras),
                      IconButton(icon: const Icon(Icons.add_circle, color: duoBg), onPressed: mostrarDialogoCrear),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- BOTONES GRANDES (Reglas y Packs) ---
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: configurarModos,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: duoBeige, // <--- NUEVO COLOR
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: duoBorder, width: 2),
                            boxShadow: const [BoxShadow(color: duoBorder, offset: Offset(0,4))]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book, color: duoBg, size: 30),
                            Text("REGLAS", style: duoFont(size: 14, color: duoBg)),
                            Text(emojisActivos, style: TextStyle(fontSize: 12, color: duoBg.withValues(alpha: 0.6)), textAlign: TextAlign.center)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: configurarCategorias,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: duoBeige, // <--- NUEVO COLOR
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: duoBorder, width: 2),
                            boxShadow: const [BoxShadow(color: duoBorder, offset: Offset(0,4))]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.library_books, color: duoBg, size: 30),
                            Text("PACKS", style: duoFont(size: 14, color: duoBg)),
                            Text("$categoriasActivasCount Activos", style: TextStyle(color: duoBg.withValues(alpha: 0.6), fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- LISTA DE JUGADORES ---
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: duoSurface.withValues(alpha: 0.5), border: Border.all(color: duoBorder, width: 2), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: DuoInput(controller: _nameCtrl, hint: "Nombre", onSubmitted: (_) => agregarJugador())),
                        const SizedBox(width: 10),
                        SizedBox(width: 60, child: DuoButton(text: "+", color: AppTheme.primary, onPressed: agregarJugador))
                      ]),
                      const SizedBox(height: 15),
                      Expanded(
                        child: jugadores.isEmpty
                            ? const Center(child: Text("Agrega jugadores...", style: TextStyle(color: duoTextSub, fontSize: 18)))
                            : ListView.builder(
                          itemCount: jugadores.length,
                          itemBuilder: (context, index) {
                            String nombre = jugadores[index];
                            int pts = puntajes[nombre] ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(color: duoSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: duoBorder, width: 2), boxShadow: const [BoxShadow(color: duoBorder, offset: Offset(0,3))]),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    CircleAvatar(backgroundColor: AppTheme.primary, radius: 15, child: const Icon(Icons.person, color: duoBg, size: 20)),
                                    const SizedBox(width: 10),
                                    Text("$nombre ($pts pts)", style: duoFont(size: 18))
                                  ]),
                                  GestureDetector(onTap: () => borrarJugador(index), child: const Icon(Icons.close, color: duoRed))
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (maxUI > 1) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("IMPOSTORES: ", style: duoFont(size: 18)),
                  Text("$cantidadImpostores", style: duoFont(size: 24, color: duoRed))
                ]),
                Slider(
                    value: cantidadImpostores.toDouble(),
                    min: 1,
                    max: maxUI.toDouble(),
                    divisions: maxUI - 1,
                    activeColor: duoRed,
                    inactiveColor: duoBorder,
                    onChanged: (val) {
                      setState(() => cantidadImpostores = val.toInt());
                      _guardarTodo();
                    }
                ),
              ],
              SizedBox(width: double.infinity, child: DuoButton(text: "INICIAR PARTIDA", color: AppTheme.primary, onPressed: jugadores.length >= 3 ? iniciarPartida : null)),
            ],
          ),
        ),
      ),
    );
  }
}