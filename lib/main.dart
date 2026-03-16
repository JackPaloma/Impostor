import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/lobby/lobby.dart'; // <--- NUEVA RUTA APUNTANDO A LA CARPETA LOBBY

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: const MenuLobby(),
    );
  }
}