import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //
import 'screens/lobby.dart';
import 'theme.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquea la orientación de forma permanente en vertical
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
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: duoBg,
      ),
      home: const MenuLobby(),
    );
  }
}