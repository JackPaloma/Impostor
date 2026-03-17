import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Para saber si estamos en la Web

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/lobby/lobby.dart';
import 'screens/web/invitado_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Impostor',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE3CA94),
        scaffoldBackgroundColor: const Color(0xFF0A0705),
      ),
      home: const PantallaCargaFirebase(),
    );
  }
}

class PantallaCargaFirebase extends StatefulWidget {
  const PantallaCargaFirebase({super.key});

  @override
  State<PantallaCargaFirebase> createState() => _PantallaCargaFirebaseState();
}

class _PantallaCargaFirebaseState extends State<PantallaCargaFirebase> {
  Future<void>? _inicializacion;

  @override
  void initState() {
    super.initState();
    _inicializacion = _iniciarFirebase();
  }

  Future<void> _iniciarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _inicializacion,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent))));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          // 🔥 LECTURA DE URL INFALIBLE 🔥
          if (kIsWeb) {
            String codigoSala = "";

            // Método 1: Leer el parámetro nativo directamente (sin #)
            String? paramNativo = Uri.base.queryParameters['sala'];
            if (paramNativo != null && paramNativo.isNotEmpty) {
              codigoSala = paramNativo;
            } else {
              // Método 2: Por si acaso el navegador metió el # de todas formas
              String urlCompleta = Uri.base.toString();
              if (urlCompleta.contains('sala=')) {
                codigoSala = urlCompleta.split('sala=')[1].split('&')[0].replaceAll('#', '').replaceAll('/', '');
              }
            }

            // Si logramos capturar el código, ¡A la pantalla de invitados!
            if (codigoSala.isNotEmpty) {
              return PantallaInvitadoWeb(codigoSala: codigoSala);
            }
          }

          // Si no es web o no hay código, abre el celular del Líder normal
          return const MenuLobby();
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Color(0xFFE3CA94))),
        );
      },
    );
  }
}