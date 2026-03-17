import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../datos.dart';
import '../../theme.dart';
import '../../models.dart';
import '../../widgets.dart';
import '../roles/juego.dart';

import 'lobby_colors.dart';
import 'lobby_components.dart';

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
  Map<String, String> fotosJugadores = {};
  List<String> jugadores = [];
  int cantidadImpostores = 1;
  bool usarPersonalizadas = false;
  List<CartaJuego> packPersonalizado = [];
  late ConfiguracionJuego config;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.puntajesGuardados != null) {
      puntajes = widget.puntajesGuardados!;
      jugadores = puntajes.keys.toList();
    }

    if (widget.configGuardada != null) {
      config = widget.configGuardada!;

      for (var key in baseDeDatos.keys) {
        if (!config.categoriasActivas.containsKey(key)) {
          config.categoriasActivas[key] = true;
        }
      }
    } else {
      Map<String, bool> cats = {};
      for (var key in baseDeDatos.keys) { cats[key] = true; }
      config = ConfiguracionJuego(categoriasActivas: cats);
    }

    _cargarDatosGuardados();
  }

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
      String? fotosString = prefs.getString('fotos_jugadores');
      if (fotosString != null) {
        Map<String, dynamic> decodedFotos = jsonDecode(fotosString);
        fotosJugadores = decodedFotos.map((key, value) => MapEntry(key, value as String));
      }
      String? palabrasString = prefs.getString('palabras_propias');
      if (palabrasString != null) {
        List<dynamic> decodedList = jsonDecode(palabrasString);
        packPersonalizado = decodedList.map((item) => CartaJuego.fromJson(item)).toList();
      }
      usarPersonalizadas = prefs.getBool('usar_personalizadas') ?? false;
      cantidadImpostores = prefs.getInt('cantidad_impostores') ?? 1;
      if (cantidadImpostores > maxImpostoresPermitidos) cantidadImpostores = maxImpostoresPermitidos;
    });
  }

  Future<void> _guardarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('puntajes', jsonEncode(puntajes));
    prefs.setString('fotos_jugadores', jsonEncode(fotosJugadores));

    List<dynamic> jsonList = packPersonalizado.map((e) => e.toJson()).toList();
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
      fotosJugadores.remove(nombre);
      jugadores.removeAt(index);
      if (cantidadImpostores > maxImpostoresPermitidos) cantidadImpostores = maxImpostoresPermitidos;
    });
    _guardarTodo();
  }

  void reordenarJugadores(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final String jugadorMovido = jugadores.removeAt(oldIndex);
      jugadores.insert(newIndex, jugadorMovido);
      Map<String, int> nuevoPuntaje = {};
      for (String nombre in jugadores) { nuevoPuntaje[nombre] = puntajes[nombre]!; }
      puntajes = nuevoPuntaje;
    });
    _guardarTodo();
  }

  void _mostrarOpcionesFoto(String nombre) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1510),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: lobbyGoldDark, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))]
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("FOTO DE $nombre", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lobbyGold)),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.camera, color: lobbyGold, size: 24),
                title: const Text('Tomar Foto', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800);
                  if (photo != null) { setState(() => fotosJugadores[nombre] = photo.path); _guardarTodo(); }
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.image, color: lobbyGold, size: 24),
                title: const Text('Elegir de la Galería', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
                  if (image != null) { setState(() => fotosJugadores[nombre] = image.path); _guardarTodo(); }
                },
              ),
              if (fotosJugadores.containsKey(nombre))
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.trashCan, color: jewelRed, size: 24),
                  title: const Text('Borrar Foto', style: TextStyle(color: jewelRed, fontWeight: FontWeight.w600, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => fotosJugadores.remove(nombre));
                    _guardarTodo();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(int index) {
    String nombreAnterior = jugadores[index];
    TextEditingController editCtrl = TextEditingController(text: nombreAnterior);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1510),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
          title: const Text("EDITAR JUGADOR", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold)),
          content: GoldInput(controller: editCtrl, hint: "Nuevo nombre"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: lobbyGoldDark, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () {
                  String nuevoNombre = editCtrl.text.trim();
                  if (nuevoNombre.isNotEmpty && nuevoNombre != nombreAnterior && !puntajes.containsKey(nuevoNombre)) {
                    setState(() {
                      int pts = puntajes[nombreAnterior]!;
                      String? fotoPath = fotosJugadores[nombreAnterior];
                      puntajes.remove(nombreAnterior);
                      fotosJugadores.remove(nombreAnterior);
                      puntajes[nuevoNombre] = pts;
                      if(fotoPath != null) fotosJugadores[nuevoNombre] = fotoPath;
                      jugadores[index] = nuevoNombre;
                    });
                    _guardarTodo();
                  }
                  Navigator.pop(context);
                },
                child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        )
    );
  }

  void agregarPalabra() {
    if (_palabraCtrl.text.isNotEmpty && _pistaCtrl.text.isNotEmpty && _categoriaCtrl.text.isNotEmpty) {
      setState(() {
        packPersonalizado.add(CartaJuego(_palabraCtrl.text, _pistaCtrl.text, categoria: _categoriaCtrl.text));
        _palabraCtrl.clear(); _pistaCtrl.clear(); _categoriaCtrl.clear();
      });
      _guardarTodo();
      Navigator.pop(context);
    }
  }

  void borrarPalabraPersonalizada(int index) {
    setState(() => packPersonalizado.removeAt(index));
    _guardarTodo();
  }

  void mostrarDialogoCrear() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1510),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
            title: const Text("CREAR PALABRA", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoldInput(controller: _palabraCtrl, hint: "Palabra"), const SizedBox(height: 10),
                      GoldInput(controller: _pistaCtrl, hint: "Pista"), const SizedBox(height: 10),
                      GoldInput(controller: _categoriaCtrl, hint: "Categoría"),
                    ]
                )
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: jewelGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: agregarPalabra,
                  child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ]
        )
    );
  }

  void gestionarPalabras() {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
                backgroundColor: const Color(0xFF1E1510),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
                title: const Text("MIS PALABRAS", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold)),
                content: SizedBox(
                    width: double.maxFinite, height: 300,
                    child: packPersonalizado.isEmpty ? const Center(child: Text("Lista vacía", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600))) : ListView.builder(
                        itemCount: packPersonalizado.length,
                        itemBuilder: (context, index) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: goldDark, width: 1))),
                            child: ListTile(
                              title: Text(packPersonalizado[index].palabra, style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 18)),
                              subtitle: Text("Pista: ${packPersonalizado[index].pista}", style: const TextStyle(color: lobbyGoldDark, fontWeight: FontWeight.w500)),
                              trailing: IconButton(icon: const FaIcon(FontAwesomeIcons.trashCan, color: jewelRed, size: 24), onPressed: () { borrarPalabraPersonalizada(index); setStateDialog(() {}); }),
                            )
                        )
                    )
                ),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ebonyInput, foregroundColor: textMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CERRAR")
                  )
                ]
            )
        )
    );
  }

  void abrirConfiguracionGeneral() {
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
                backgroundColor: const Color(0xFF1E1510),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: lobbyGoldDark, width: 2)),
                title: Row(children: const [FaIcon(FontAwesomeIcons.gear, color: lobbyGold, size: 24), SizedBox(width: 10), Text("AJUSTES", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold))]),
                content: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                  decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(16)),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("SONIDO", style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
                                        IconButton(
                                            icon: FaIcon(AppTheme.sonidoActivado ? FontAwesomeIcons.volumeHigh : FontAwesomeIcons.volumeXmark, color: AppTheme.sonidoActivado ? lobbyGold : textMuted, size: 26),
                                            onPressed: () { AppTheme.toggleSound(); setStateDialog(() {}); setState(() {}); }
                                        )
                                      ]
                                  )
                              )
                            ]
                        )
                    )
                ),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: lobbyGoldDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("LISTO", style: TextStyle(fontWeight: FontWeight.bold))
                  )
                ]
            )
        )
    ).then((_) { if (mounted) setState(() {}); });
  }

  void configurarModos() {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
                backgroundColor: const Color(0xFF1E1510),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelBlue, width: 2)),
                title: const Text("REGLAS", style: TextStyle(color: jewelBlue, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("MODOS DE JUEGO", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold, fontSize: 16))),
                          GoldSwitch(title: "⏱️ Contra el Reloj", subtitle: "Gana Impostor si acaba el tiempo.", value: config.modoContraReloj, color: jewelBlue, onChanged: (v) { setStateDialog(() { config.modoContraReloj = v; if(v) config.modoCaos = false; }); }),
                          if (config.modoContraReloj) Slider(value: config.minutosReloj.toDouble(), min: 2, max: 10, divisions: 8, label: "${config.minutosReloj} min", activeColor: jewelBlue, inactiveColor: goldDark, onChanged: (val) => setStateDialog(() => config.minutosReloj = val.toInt())),
                          GoldSwitch(title: "🌀 Modo Caos", subtitle: "Nueva palabra.", value: config.modoCaos, color: jewelBlue, onChanged: (v) { setStateDialog(() { config.modoCaos = v; if(v) config.modoContraReloj = false; }); }),

                          const Divider(height: 20, color: goldDark, thickness: 1),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("ROLES ESPECIALES", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold, fontSize: 16))),
                          GoldSwitch(title: "🤫 El Silencioso", subtitle: "Silencia a uno al inicio.", value: config.rolSilencioso, color: jewelBlue, onChanged: (v) => setStateDialog(() { config.rolSilencioso = v; })),
                          GoldSwitch(title: "🔍 Detective", subtitle: "Pregunta a un jugador.", value: config.rolDetective, color: jewelBlue, onChanged: (v) => setStateDialog(() { config.rolDetective = v; })),
                          GoldSwitch(title: "🎭 Cómplice", subtitle: "Ayuda a impostores.", value: config.rolComplice, color: jewelBlue, onChanged: (v) => setStateDialog(() { config.rolComplice = v; })),

                          const Divider(height: 20, color: goldDark, thickness: 1),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("AJUSTES EXTRA", style: TextStyle(color: lobbyGold, fontWeight: FontWeight.bold, fontSize: 16))),

                          // 🔥 NUEVO: SELECTOR DE MOSTRAR CATEGORÍA
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(16), border: Border.all(color: jewelBlue, width: 1.5)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("🏷️ Mostrar Categoría", style: TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                          config.mostrarCategoria == VisibilidadCategoria.desactivado ? "Nadie ve la categoría." :
                                          config.mostrarCategoria == VisibilidadCategoria.soloInocentes ? "Solo inocentes la ven." :
                                          config.mostrarCategoria == VisibilidadCategoria.soloImpostor ? "Solo el impostor la ve." :
                                          "Todos ven la categoría.",
                                          style: const TextStyle(color: textMuted, fontSize: 11)
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF1E1510), borderRadius: BorderRadius.circular(10), border: Border.all(color: goldDark)),
                                  child: DropdownButton<VisibilidadCategoria>(
                                    value: config.mostrarCategoria,
                                    dropdownColor: const Color(0xFF1E1510),
                                    icon: const Padding(padding: EdgeInsets.only(left: 8.0), child: FaIcon(FontAwesomeIcons.chevronDown, color: jewelBlue, size: 14)),
                                    underline: const SizedBox(),
                                    style: const TextStyle(color: jewelBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                    items: const [
                                      DropdownMenuItem(value: VisibilidadCategoria.desactivado, child: Text("Desactivado")),
                                      DropdownMenuItem(value: VisibilidadCategoria.soloInocentes, child: Text("Solo Inocentes")),
                                      DropdownMenuItem(value: VisibilidadCategoria.soloImpostor, child: Text("Solo Impostor")),
                                      DropdownMenuItem(value: VisibilidadCategoria.todos, child: Text("Ambos")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setStateDialog(() {
                                          config.mostrarCategoria = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          GoldSwitch(title: "🕵️ Pista Impostor", subtitle: "Ve la PISTA.", value: config.impostorTienePista, color: jewelBlue, onChanged: (v) { setStateDialog(() { config.impostorTienePista = v; }); }),
                          GoldSwitch(title: "👥 Conocer Aliados", subtitle: "Saben quién es socio.", value: config.impostoresSeConocen, color: jewelBlue, onChanged: (v) => setStateDialog(() => config.impostoresSeConocen = v)),
                          GoldSwitch(title: "💀 Sincronía Vital", subtitle: "Mueren TODOS.", value: config.muerteSincronizada, color: jewelBlue, onChanged: (v) => setStateDialog(() => config.muerteSincronizada = v)),
                          GoldSwitch(title: "🗳️ Votación Anónima", subtitle: "Votos secretos.", value: config.modoVotacionAnonima, color: jewelBlue, onChanged: (v) => setStateDialog(() => config.modoVotacionAnonima = v))
                        ]
                    )
                ),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: jewelBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("LISTO", style: TextStyle(fontWeight: FontWeight.bold))
                  )
                ]
            )
        )
    ).then((_) { if (mounted) setState((){}); });
  }

  void configurarCategorias() {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
                backgroundColor: const Color(0xFF1E1510),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: jewelPurple, width: 2)),
                title: Row(
                  children: const [
                    FaIcon(FontAwesomeIcons.layerGroup, color: jewelPurple, size: 24),
                    SizedBox(width: 10),
                    Text("PACKS", style: TextStyle(color: jewelPurple, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ...config.categoriasActivas.keys.map((cat) {
                            bool isActivo = config.categoriasActivas[cat] ?? false;

                            List<String> partes = cat.split(' ');
                            String emoji = partes.isNotEmpty ? partes[0] : '';
                            String nombre = partes.length > 1 ? cat.substring(cat.indexOf(' ') + 1) : cat;

                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  config.categoriasActivas[cat] = !isActivo;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: isActivo ? jewelPurple.withOpacity(0.15) : ebonyInput,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isActivo ? jewelPurple : goldDark.withOpacity(0.5),
                                      width: isActivo ? 2.5 : 1.5
                                  ),
                                  boxShadow: isActivo
                                      ? [BoxShadow(color: jewelPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                                      : [],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 32)),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            child: Text(nombre,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: isActivo ? textMain : textMuted,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12
                                                )
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isActivo)
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: FaIcon(FontAwesomeIcons.solidCircleCheck, color: jewelPurple, size: 18),
                                      )
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: textMuted.withOpacity(0.3), width: 1.5),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: const Text("🚀", style: TextStyle(fontSize: 28)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("¡Nuevos\nPronto!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: textMuted.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 11)
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                ),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: jewelPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("LISTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  )
                ]
            )
        )
    ).then((_) { if (mounted) setState((){}); });
  }

  void iniciarPartida() {
    if (jugadores.length < 3) return;
    List<CartaJuego> poolPalabras = [];
    config.categoriasActivas.forEach((categoria, estaActiva) {
      if (estaActiva && baseDeDatos.containsKey(categoria)) poolPalabras.addAll(baseDeDatos[categoria]!.map((c) => CartaJuego(c.palabra, c.pista, categoria: categoria)));
    });
    if (usarPersonalizadas) {
      if (packPersonalizado.isNotEmpty) poolPalabras.addAll(packPersonalizado);
      else if (poolPalabras.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡No hay palabras disponibles!", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: jewelRed)); return; }
    }
    if (poolPalabras.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Activa al menos una categoría!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: lobbyGold)); return; }

    final carta = poolPalabras[Random().nextInt(poolPalabras.length)];
    Set<int> indicesImpostores = {};
    while (indicesImpostores.length < cantidadImpostores) { indicesImpostores.add(Random().nextInt(jugadores.length)); }
    int? indiceComplice;
    if (config.rolComplice) {
      List<int> posiblesComplices = [];
      for (int i = 0; i < jugadores.length; i++) { if (!indicesImpostores.contains(i)) posiblesComplices.add(i); }
      if (posiblesComplices.isNotEmpty) indiceComplice = posiblesComplices[Random().nextInt(posiblesComplices.length)];
    }

    List<JugadorEnPartida> listaJugadoresObj = List.generate(jugadores.length, (index) {
      return JugadorEnPartida(nombre: jugadores[index], esImpostor: indicesImpostores.contains(index), esComplice: (index == indiceComplice), rutaFoto: fotosJugadores[jugadores[index]]);
    });

    Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaJuego(listaJugadores: listaJugadoresObj, puntajes: puntajes, carta: carta, config: config, packUsado: poolPalabras)));
  }

  @override
  Widget build(BuildContext context) {
    int categoriasActivasCount = config.categoriasActivas.values.where((v) => v).length;

    String emojisActivos = "";
    if (config.modoContraReloj) emojisActivos += "⏱️ ";
    if (config.modoCaos) emojisActivos += "🌀 ";
    if (config.mostrarCategoria != VisibilidadCategoria.desactivado) emojisActivos += "🏷️ "; // 🔥 ACTUALIZADO
    if (config.rolSilencioso) emojisActivos += "🤫 ";
    if (config.impostorTienePista) emojisActivos += "🕵️ ";
    if (config.modoVotacionAnonima) emojisActivos += "🗳️ ";
    if (config.impostoresSeConocen) emojisActivos += "👥 ";
    if (config.muerteSincronizada) emojisActivos += "💀 ";
    if (config.rolDetective) emojisActivos += "🔍 ";
    if (config.rolComplice) emojisActivos += "🎭 ";
    if (emojisActivos.isEmpty) emojisActivos = "Clásico";

    int maxUI = maxImpostoresPermitidos;
    if (cantidadImpostores > maxUI) cantidadImpostores = maxUI > 0 ? maxUI : 1;
    List<int> sortedScores = puntajes.values.where((p) => p > 0).toSet().toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DuoFondo(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                // 1. TÍTULO Y AJUSTES
                LobbyHeader(onSettingsTap: abrirConfiguracionGeneral),
                const SizedBox(height: 20),

                // 2. LISTA DE JUGADORES
                Expanded(
                  child: PremiumCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(16), border: Border.all(color: goldDark, width: 1)),
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Añadir jugador...", hintStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
                                  onSubmitted: (_) => agregarJugador(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: agregarJugador,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: lobbyGold,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 5)]
                                ),
                                child: const FaIcon(FontAwesomeIcons.plus, color: Color(0xFF2A1B0E), size: 22),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: jugadores.isEmpty
                              ? const Center(child: Text("Faltan jugadores...", style: TextStyle(color: textMuted, fontSize: 18, fontWeight: FontWeight.w600)))
                              : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: reordenarJugadores,
                            proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 0, child: child),
                            itemCount: jugadores.length,
                            itemBuilder: (context, index) {
                              String nombre = jugadores[index];
                              int pts = puntajes[nombre] ?? 0;
                              bool tieneFoto = fotosJugadores.containsKey(nombre);

                              Widget? medallaWidget;
                              if (pts > 0) {
                                if (sortedScores.isNotEmpty && pts == sortedScores[0]) medallaWidget = const FaIcon(FontAwesomeIcons.crown, color: lobbyGold, size: 18);
                                else if (sortedScores.length > 1 && pts == sortedScores[1]) medallaWidget = const FaIcon(FontAwesomeIcons.medal, color: Color(0xFFC0C0C0), size: 18);
                                else if (sortedScores.length > 2 && pts == sortedScores[2]) medallaWidget = const FaIcon(FontAwesomeIcons.medal, color: Color(0xFFCD7F32), size: 18);
                              }

                              double swipeProgress = 0.0;

                              return StatefulBuilder(
                                  key: ValueKey(nombre),
                                  builder: (context, setStateItem) {
                                    double currentRadius = swipeProgress > 0.0 ? 0.0 : 16.0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(currentRadius),
                                        child: Dismissible(
                                          key: ValueKey('dismiss_$nombre'),
                                          direction: DismissDirection.horizontal,
                                          onUpdate: (details) {
                                            bool isSwiping = details.progress > 0.0;
                                            bool wasSwiping = swipeProgress > 0.0;
                                            if (isSwiping != wasSwiping) {
                                              setStateItem(() {
                                                swipeProgress = details.progress;
                                              });
                                            }
                                          },
                                          background: Container(
                                            color: jewelGreen,
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: const FaIcon(FontAwesomeIcons.pen, color: Colors.white, size: 24),
                                          ),
                                          secondaryBackground: Container(
                                            color: jewelRed,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white, size: 24),
                                          ),
                                          confirmDismiss: (direction) async {
                                            if (direction == DismissDirection.endToStart) return true;
                                            else if (direction == DismissDirection.startToEnd) { _mostrarDialogoEditar(index); return false; }
                                            return false;
                                          },
                                          onDismissed: (direction) { if (direction == DismissDirection.endToStart) borrarJugador(index); },

                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: ebonyInput,
                                                borderRadius: BorderRadius.circular(currentRadius),
                                                border: Border.all(color: goldDark, width: 1.5)
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(children: [
                                                  ReorderableDragStartListener(index: index, child: const Padding(padding: EdgeInsets.only(right: 12.0), child: FaIcon(FontAwesomeIcons.gripVertical, color: textMuted, size: 20))),
                                                  GestureDetector(
                                                    onTap: () => _mostrarOpcionesFoto(nombre),
                                                    child: CircleAvatar(
                                                      backgroundColor: goldDark,
                                                      radius: 20,
                                                      backgroundImage: tieneFoto ? FileImage(File(fotosJugadores[nombre]!)) : null,
                                                      child: tieneFoto ? null : const FaIcon(FontAwesomeIcons.camera, color: lobbyGold, size: 16),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textMain))
                                                ]),
                                                Row(
                                                  children: [
                                                    if (medallaWidget != null) medallaWidget,
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(color: goldDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: lobbyGoldDark, width: 1)),
                                                      child: Text("$pts pts", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: lobbyGold)),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. SELECTOR DE IMPOSTORES
                if (maxUI > 1) ...[
                  PremiumCard(
                    color: const Color(0xCC3E1414),
                    borderColor: jewelRed.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: jewelRed.withOpacity(0.15), shape: BoxShape.circle), child: const FaIcon(FontAwesomeIcons.userSecret, color: jewelRed, size: 24)),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("IMPOSTORES", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain)), Text("Máximo $maxUI permitidos", style: const TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 12))]),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(onTap: () { if (cantidadImpostores > 1) { setState(() => cantidadImpostores--); _guardarTodo(); } }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(10), border: Border.all(color: goldDark, width: 1.5)), child: const FaIcon(FontAwesomeIcons.minus, color: jewelRed, size: 16))),
                            const SizedBox(width: 15),
                            Text("$cantidadImpostores", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lobbyGold)),
                            const SizedBox(width: 15),
                            GestureDetector(onTap: () { if (cantidadImpostores < maxUI) { setState(() => cantidadImpostores++); _guardarTodo(); } }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: ebonyInput, borderRadius: BorderRadius.circular(10), border: Border.all(color: goldDark, width: 1.5)), child: const FaIcon(FontAwesomeIcons.plus, color: jewelGreen, size: 16))),
                          ],
                        )
                      ],
                    ),
                  ),
                ],

                // 4. PALABRAS PROPIAS
                PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lobbyGold.withOpacity(0.15), shape: BoxShape.circle), child: const FaIcon(FontAwesomeIcons.penToSquare, color: lobbyGold, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PALABRAS PROPIAS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain)), Text(usarPersonalizadas ? "${packPersonalizado.length} activas" : "Desactivadas", style: const TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 12))])),
                      Switch(value: usarPersonalizadas, activeColor: lobbyGold, activeTrackColor: lobbyGold.withOpacity(0.3), inactiveThumbColor: textMuted, inactiveTrackColor: ebonyInput, onChanged: (v) { setState(() => usarPersonalizadas = v); _guardarTodo(); }),
                      if (usarPersonalizadas) ...[
                        const SizedBox(width: 10),
                        GestureDetector(onTap: gestionarPalabras, child: const FaIcon(FontAwesomeIcons.listUl, color: lobbyGold, size: 24)),
                        const SizedBox(width: 15),
                        GestureDetector(onTap: mostrarDialogoCrear, child: const FaIcon(FontAwesomeIcons.circlePlus, color: lobbyGold, size: 24)),
                      ]
                    ],
                  ),
                ),

                // 5. BOTONES DE REGLAS Y PACKS
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: configurarModos, child: PremiumCard(padding: EdgeInsets.zero, child: SizedBox(height: 75, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const FaIcon(FontAwesomeIcons.bookOpen, color: jewelBlue, size: 24), const SizedBox(height: 6), const Text("REGLAS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)), Text(emojisActivos, style: const TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center)]))))),
                    const SizedBox(width: 15),
                    Expanded(child: GestureDetector(onTap: configurarCategorias, child: PremiumCard(padding: EdgeInsets.zero, child: SizedBox(height: 75, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const FaIcon(FontAwesomeIcons.layerGroup, color: jewelPurple, size: 24), const SizedBox(height: 6), const Text("PACKS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)), Text("$categoriasActivasCount Activos", style: const TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 10))]))))),
                  ],
                ),
                const SizedBox(height: 10),

                // 6. BOTÓN START GIGANTE
                StartGameButton(
                    isActive: jugadores.length >= 3,
                    onTap: jugadores.length >= 3 ? iniciarPartida : null
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}