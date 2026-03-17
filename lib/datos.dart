// lib/datos.dart
import 'models.dart';

// 1. IMPORTA TODOS TUS PACKS AQUÍ
import 'packs/pack_animales.dart';
import 'packs/pack_lol.dart';
import 'packs/pack_cine_tv.dart';
import 'packs/pack_marcas.dart';
import 'packs/pack_anime.dart';

// Añade los demás a medida que los vayas creando...

// 2. EL GESTOR CENTRAL
// El nombre que pongas entre comillas es el que aparecerá mágicamente en el Lobby
final Map<String, List<CartaJuego>> baseDeDatos = {
  "⚔️ LoL Campeones": packlol,
  "🐾 Animales": packAnimales,
  "🎬 Cine y TV": packCineTv,
  "🏷️ Marcas": packMarcas,
  "⛩️ Anime": packAnime,

};